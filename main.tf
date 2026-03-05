##########################
# LOAD LAB VARS (lab_var module)
##########################
module "vars" {
  source   = "./lab_var"
  lab_file = coalesce(var.lab_file, "lab1")
}


##########################
# TAGGING MODULE
##########################
module "tagging" {
  source = "./modules/tagging"

  environment    = local.global_tags.environment
  provisioned_by = local.global_tags.provisioned_by
  project        = local.global_tags.project
  owner          = local.global_tags.owner
}

##########################
# S3 MODULE
##########################
module "s3" {
  source           = "./modules/s3"
  bucket_name        = local.configuration.s3.images_bucket_name
  force_destroy      = true
  tags               = local.global_tags
  versioning_enabled = false

  # bucket_policy_json = data.aws_iam_policy_document.s3_allow_cloudfront_read.json
}

##########################
# IAM MODULE
##########################
module "iam" {
  source = "./modules/iam"

  name_prefix = local.global_tags.environment
  tags        = local.global_tags

  aws_region = var.aws_region

  # deny_all_s3        = try(local.configuration.ec2.attach_deny_s3, false)
  allow_rds_describe = true

  enable_secrets_read = true
  secret_arns = compact([
    try(module.rds.master_user_secret_arn, null),
    try(module.app_secrets.arn, null),
    try(module.mq.secret_arn, null)
  ])
  enable_product_image_upload = local.configuration.ec2.enable_product_image_upload
  s3_bucket_arn               = module.s3.bucket_arn

  # Only set this if your secrets use a customer-managed KMS key
  # kms_key_arn = try(local.configuration.kms.kms_key_arn, null)

}

##########################
# VPC MODULE
##########################
module "vpc" {
  source      = "./modules/vpc"
  name_prefix = local.global_tags.environment

  vpc_cidr = local.configuration.vpc.cidr

  public_subnets = slice(
    local.configuration.vpc.public_subnets,
    0,
    local.configuration.vpc.subnet_count
  )

  private_subnets = slice(
    local.configuration.vpc.private_subnets,
    0,
    local.configuration.vpc.subnet_count
  )

  # optional (defaults to true)
  enable_nat_gateway = true

  tags = local.vpc_tags
}


module "ec2_public" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]

  ami_id        = local.configuration.ec2.ami_id
  instance_type = local.configuration.ec2.instance_type
  key_name      = aws_key_pair.this.key_name

  enable_ssh_from_sg = false
  enable_app_from_sg = false

  associate_public_ip_address = true

  # iam_instance_profile = module.iam.instance_profile_name
  # user_data            = local.configuration.user_data

  ssh_cidr_blocks = local.effective_ssh_cidr_blocks

  tags = merge(local.ec2_tags, {
    Name = "${local.global_tags.environment}-bastion"
    Role = "bastion"
  })
}

module "ec2_private" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.private_subnet_ids[0]

  ami_id        = local.configuration.ec2.ami_id
  instance_type = local.configuration.ec2.instance_type
  key_name      = aws_key_pair.this.key_name

  associate_public_ip_address = false

  iam_instance_profile = module.iam.instance_profile_name
  user_data            = local.user_data_rendered

  # 🔒 No direct SSH from internet
  ssh_cidr_blocks  = []
  enable_ssh_from_sg = true
  ssh_source_sg_id = module.ec2_public.security_group_id

  # ALB -> app
  enable_app_from_sg = true
  app_port              = 80
  allow_app_from_sg_id  = module.lb.security_group_id

  tags = merge(local.ec2_tags, {
    Name = "${local.global_tags.environment}-private"
    Role = "private"
  })
}

###########################
# ALB MODULE
###########################

module "lb" {
  source = "./modules/alb"

  name_prefix = local.global_tags.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  tags        = local.global_tags

  target_instance_id = module.ec2_private.instance_id
  target_port        = 80

  healthcheck_path   = "/health"
}


module "rds" {
  source = "./modules/rds"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine               = local.configuration.db.engine
  engine_version       = local.configuration.db.engine_version
  instance_class       = local.configuration.db.instance_class
  allocated_storage_gb = local.configuration.db.allocated_storage_gb
  storage_type         = try(local.configuration.db.storage_type, "gp3")

  db_identifier = local.configuration.db.db_identifier
  db_name       = local.configuration.db.db_name
  username      = local.configuration.db.username
  port          = local.configuration.db.port

  allowed_sg_ids = [module.ec2_private.security_group_id]

  publicly_accessible   = local.configuration.db.publicly_accessible
  multi_az              = local.configuration.db.multi_az
  backup_retention_days = local.configuration.db.backup_retention_days
  deletion_protection   = local.configuration.db.deletion_protection
  skip_final_snapshot   = local.configuration.db.skip_final_snapshot
  apply_immediately     = local.configuration.db.apply_immediately

  tags = module.tagging.tags
}

module "mq" {
  source = "./modules/mq"

  name_prefix         = local.global_tags.environment
  tags                = local.global_tags

  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  # allow only your private app EC2 SG
  allowed_sg_ids = [module.ec2_private.security_group_id]

  deployment_mode    = "SINGLE_INSTANCE"
  host_instance_type = "mq.t3.micro"

  # optional:
  enable_management_ingress = false
  recovery_window_days = try(local.configuration.mq.recovery_window_days, 7)
}


module "cloudfront_s3" {
  source = "./modules/cloudfront_s3"

  name_prefix = local.global_tags.environment
  tags        = local.global_tags

  bucket_id                   = module.s3.bucket_id
  bucket_arn                  = module.s3.bucket_arn
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  # bucket_policy_json = data.aws_iam_policy_document.s3_allow_cloudfront_read.json

  # Optional custom domain:
  # aliases             = ["img.yourdomain.com"]
  # acm_certificate_arn = var.cloudfront_acm_cert_arn  # must be us-east-1
}


module "ses" {
  source = "./modules/ses"

  name_prefix        = local.global_tags.environment
  tags               = local.global_tags
  from_email_address = local.configuration.secrets.from_email_address
}


module "app_secrets" {
  source = "./modules/secrets_manager_app"

  name_prefix = local.global_tags.environment
  secret_name = "microshop/app"
  tags        = local.global_tags

  recovery_window_in_days = 7

  secret_data = {
    JWT_SECRET     = local.configuration.secrets.jwt_secret
    ADMIN_EMAIL    = local.configuration.secrets.admin_email
    ADMIN_PASSWORD = local.configuration.secrets.admin_password

    SMTP_HOST     = local.configuration.secrets.smtp_host
    SMTP_PORT     = tostring(local.configuration.secrets.smtp_port)
    SMTP_USE_TLS  = tostring(local.configuration.secrets.smtp_use_tls)
    SMTP_USE_AUTH = tostring(local.configuration.secrets.smtp_use_auth)
    SMTP_USER     = local.configuration.secrets.smtp_user
    SMTP_PASS     = local.configuration.secrets.smtp_pass
    FROM_EMAIL    = local.configuration.secrets.from_email
  }
}