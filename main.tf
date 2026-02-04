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
# IAM MODULE
##########################
module "iam" {
  source = "./modules/iam"

  name_prefix = local.global_tags.environment
  tags        = local.global_tags

  deny_all_s3 = try(local.configuration.ec2.attach_deny_s3, false)
}


##########################
# S3 MODULE
##########################
module "s3" {
  source           = "./modules/s3"
  for_each         = try(local.configuration.s3, {})
  global_variables = local.global_variables
  tags             = module.tagging.tags
  bucket_name      = try(each.value.bucket_name, null)
}

##########################
# VPC MODULE
##########################
module "vpc" {
  source   = "./modules/vpc"
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

  tags = local.vpc_tags
}


module "ebs_data" {
  source = "./modules/ebs"

  name              = "${local.global_tags.environment}-data"
  availability_zone = module.ec2_private.availability_zone
  instance_id       = module.ec2_private.instance_id

  size        = 10
  device_name = "/dev/xvdf"

  tags = local.ec2_tags
}


##########################
# EC2 MODULE
##########################
# module "ec2" {
#   source        = "./modules/ec2"
#   vpc_id        = module.vpc.vpc_id
#   ami_id        = try(local.configuration.ec2.ami_id, null)
#   instance_type = local.configuration.ec2.instance_type
#   key_name      = aws_key_pair.this.key_name
#   subnet_id     = module.vpc.public_subnet_ids[0]
#   tags          = local.ec2_tags

#   iam_instance_profile = module.iam.instance_profile_name
#   user_data            = local.configuration.ec2_user_data
#   ssh_cidr_blocks      = local.effective_ssh_cidr_blocks
# }

module "ec2_public" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  ami_id        = try(local.configuration.asg_alb.ami_id, null)
  instance_type = local.configuration.asg_alb.instance_type
  key_name      = aws_key_pair.this.key_name
  subnet_id     = module.vpc.public_subnet_ids[0]
  tags          = merge(local.ec2_tags, { Role = "bastion" })

  iam_instance_profile = module.iam.instance_profile_name
  user_data            = local.configuration.user_data
  ssh_cidr_blocks      = local.effective_ssh_cidr_blocks
}

module "ec2_private" {
  source        = "./modules/ec2"
  vpc_id        = module.vpc.vpc_id
  ami_id        = try(local.configuration.asg_alb.ami_id, null)
  instance_type = local.configuration.asg_alb.instance_type
  key_name      = aws_key_pair.this.key_name
  subnet_id     = module.vpc.private_subnet_ids[0]
  tags          = merge(local.ec2_tags, { Role = "private" })

  iam_instance_profile = module.iam.instance_profile_name
  user_data            = local.configuration.user_data

  ssh_cidr_blocks  = []
  ssh_source_sg_id = module.ec2_public.security_group_id
}

###########################
# ASG + ALB MODULE
###########################
module "asg_alb" {
  source = "./modules/asg_alb"

  name               = local.global_tags.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  instance_type = local.configuration.asg_alb.instance_type
  ami_id        = try(local.configuration.asg_alb.ami_id, null)
  key_name      = aws_key_pair.this.key_name

  min_size         = local.configuration.asg_alb.min_size
  max_size         = local.configuration.asg_alb.max_size
  desired_capacity = local.configuration.asg_alb.desired_capacity

  alb_listener_port = local.configuration.asg_alb.alb_listener_port
  target_port       = local.configuration.asg_alb.target_port
  health_check_path = local.configuration.asg_alb.health_check_path

  user_data = local.configuration.user_data
  tags      = local.ec2_tags
}

