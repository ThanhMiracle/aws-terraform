##########################
# LOAD ENV VARS (lab_var module)
##########################
module "vars" {
  source      = "./lab_var"
  environment = coalesce(var.environment, "dev")
}

##########################
# TAGGING MODULE
##########################
module "tagging" {
  source = "./modules/tagging"

  environment    = local.environment
  provisioned_by = local.global_tags.provisioned_by
  project        = local.global_tags.project
  owner          = local.global_tags.owner
}

##########################
# S3 MODULE
##########################
module "s3" {
  source             = "./modules/s3"
  bucket_name        = local.configuration.s3.images_bucket_name
  force_destroy      = true
  versioning_enabled = false
  tags               = local.s3_tags
}

##########################
# IAM MODULE
##########################
module "iam" {
  source = "./modules/iam"

  name_prefix = local.environment
  tags        = local.iam_tags

  allow_rds_describe = true

  enable_secrets_read = true
  secret_arns = compact([
    try(module.rds.master_user_secret_arn, null),
    try(module.app_secrets.arn, null),
    try(module.mq.secret_arn, null)
  ])

  enable_product_image_upload = local.configuration.ec2.enable_product_image_upload
  s3_bucket_arn               = module.s3.bucket_arn
  enable_ses_send             = true
}

##########################
# VPC MODULE
##########################
module "vpc" {
  source      = "./modules/vpc"
  name_prefix = local.environment

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

  enable_nat_gateway = true

  tags = local.vpc_tags
}

##########################
# EC2 PUBLIC / BASTION
##########################
module "ec2_public" {
  source    = "./modules/ec2"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  ami_id        = local.configuration.ec2.ami_id
  instance_type = local.configuration.ec2.instance_type
  key_name      = aws_key_pair.this.key_name

  enable_ssh_from_sg = false
  enable_app_from_sg = false

  associate_public_ip_address = true
  ssh_cidr_blocks             = local.effective_ssh_cidr_blocks

  tags = merge(local.ec2_tags, {
    Name = "${local.environment}-bastion"
    Role = "bastion"
  })
}

##########################
# EC2 PRIVATE / APP
##########################
module "ec2_private" {
  source    = "./modules/ec2"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]

  ami_id        = local.configuration.ec2.ami_id
  instance_type = local.configuration.ec2.instance_type
  key_name      = aws_key_pair.this.key_name

  associate_public_ip_address = false

  iam_instance_profile = module.iam.instance_profile_name
  user_data            = local.user_data_rendered

  ssh_cidr_blocks    = []
  enable_ssh_from_sg = true
  ssh_source_sg_id   = module.ec2_public.security_group_id

  enable_app_from_sg = false
  app_port           = try(local.configuration.lb.target_port, 80)

  tags = merge(local.ec2_tags, {
    Name = "${local.environment}-private"
    Role = "private"
  })
}

###########################
# ALB MODULE
###########################
module "lb" {
  source = "./modules/alb"

  name_prefix = local.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids
  tags        = local.alb_tags

  target_instance_id    = module.ec2_private.instance_id
  target_port           = try(local.configuration.lb.target_port, 80)
  healthcheck_path      = try(local.configuration.lb.healthcheck_path, "/health")
  app_security_group_id = module.ec2_private.security_group_id
  app_port              = try(local.configuration.lb.target_port, 80)
}

##########################
# RDS MODULE
##########################
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

  tags = local.rds_tags
}

##########################
# MQ MODULE
##########################
module "mq" {
  source = "./modules/mq"

  name_prefix = local.environment
  tags        = local.mq_tags

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_sg_ids = [module.ec2_private.security_group_id]

  deployment_mode           = try(local.configuration.mq.deployment_mode, "SINGLE_INSTANCE")
  host_instance_type        = try(local.configuration.mq.host_instance_type, "mq.t3.micro")
  enable_management_ingress = false
  recovery_window_days      = try(local.configuration.mq.recovery_window_days, 7)
}

##########################
# SES MODULE
##########################
module "ses" {
  source = "./modules/ses"

  name_prefix        = local.environment
  tags               = local.ses_tags
  from_email_address = local.configuration.secrets.from_email_address
}

##########################
# APP SECRETS MODULE
##########################
module "app_secrets" {
  source = "./modules/secrets_manager_app"

  name_prefix = local.environment
  secret_name = "${local.environment}/microshop/app"
  tags        = local.secrets_tags

  recovery_window_in_days = local.configuration.secrets.recovery_window_days

  secret_data = {
    JWT_SECRET     = local.configuration.secrets.jwt_secret
    ADMIN_EMAIL    = local.configuration.secrets.admin_email
    ADMIN_PASSWORD = local.configuration.secrets.admin_password

    SMTP_HOST     = local.configuration.secrets.smtp_host
    SMTP_PORT     = tostring(local.configuration.secrets.smtp_port)
    SMTP_USE_TLS  = tostring(local.configuration.secrets.smtp_use_tls)
    SMTP_USE_AUTH = tostring(local.configuration.secrets.smtp_use_auth)
    SMTP_USER     = module.ses.smtp_username
    SMTP_PASS     = module.ses.smtp_password
    FROM_EMAIL    = local.configuration.secrets.from_email
  }
}