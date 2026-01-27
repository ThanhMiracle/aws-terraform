resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
  tags       = local.tags
}

module "vpc" {
  source = "./modules/vpc"

  name       = "lab"
  cidr_block = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  ssh_allowed_ip       = var.ssh_allowed_ip
  azs  = ["ap-southeast-1a", "ap-southeast-1b"]
  tags = local.tags
}

module "ec2_bastion" {
  source = "./modules/ec2"

  name          = "lab-bastion"
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]
  sg_ids        = [aws_security_group.bastion.id]

  public_ip   = true
  key_name    = aws_key_pair.this.key_name
  profile_name = var.profile_name
}

module "ec2_private" {
  source = "./modules/ec2"

  name          = "lab-private"
  instance_type = var.instance_type
  subnet_id     = module.vpc.private_subnet_ids[0]
  sg_ids        = [aws_security_group.private.id]

  public_ip   = false
  key_name    = aws_key_pair.this.key_name
  profile_name = var.profile_name
}

module "ebs_bastion_data" {
  source = "./modules/ebs"

  name              = "lab-bastion-data"
  availability_zone = module.ec2_bastion.availability_zone
  instance_id       = module.ec2_bastion.instance_id

  size        = 20
  type        = "gp3"
  device_name = "/dev/xvdf"

  tags = local.tags
}

