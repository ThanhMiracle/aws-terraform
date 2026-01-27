############################
# VPC
############################
module "vpc" {
  source = "./modules/vpc"

  name       = "lab"
  cidr_block = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

  azs  = ["ap-southeast-1a", "ap-southeast-1b"]
  tags = local.tags
}

############################
# Identify Account (used for unique bucket name)
############################
data "aws_caller_identity" "current" {}

############################
# S3 bucket for product images (private)
############################
resource "aws_s3_bucket" "product_images" {
  bucket = "lab-product-images-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket                  = aws_s3_bucket.product_images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# IAM: EC2 role -> allow S3 access to products/*
############################
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "lab-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

data "aws_iam_policy_document" "ec2_s3_product_images" {
  statement {
    sid     = "ListBucketPrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.product_images.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["products/*"]
    }
  }

  statement {
    sid    = "ObjectRWInProductsPrefix"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.product_images.arn}/products/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_s3_product_images" {
  name   = "lab-ec2-s3-product-images"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_s3_product_images.json
}

resource "aws_iam_instance_profile" "profile" {
  name = "lab-profile"
  role = aws_iam_role.ec2_role.name
}

######################################
# Secrets Manager (DB_HOST from RDS in database.tf + S3_BUCKET)
######################################
resource "aws_secretsmanager_secret" "app" {
  name = "lab/app"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    # RDS is defined in database.tf
    DB_HOST = aws_db_instance.postgres.address
    DB_USER = var.db_username
    DB_PASS = var.db_password
    DB_NAME = var.db_name

    JWT_SECRET         = var.jwt_secret
    JWT_EXPIRE_MINUTES = var.jwt_expire_minutes

    MINIO_ACCESS_KEY = var.minio_access_key
    MINIO_SECRET_KEY = var.minio_secret_key
    MINIO_BUCKET     = var.minio_bucket
    MINIO_SECURE     = "false"

    S3_BUCKET = aws_s3_bucket.product_images.bucket
  })
}

######################################
# Allow EC2 to read secret
######################################
data "aws_iam_policy_document" "ec2_read_secret" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.app.arn]
  }
}

resource "aws_iam_role_policy" "ec2_read_secret" {
  name   = "lab-ec2-read-secret"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_read_secret.json
}

############################
# (Optional) S3 VPC Endpoint
############################
data "aws_route_tables" "all_in_vpc" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids   = data.aws_route_tables.all_in_vpc.ids
  tags              = local.tags
}

############################
# Key Pair
############################
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
  tags       = local.tags
}

############################
# ALB + ASG module (PUBLIC instances)
############################
module "alb_asg" {
  source = "./modules/alb"

  name   = "lab-app"
  vpc_id = module.vpc.vpc_id

  aws_region = var.aws_region

  alb_subnet_ids      = module.vpc.public_subnet_ids
  instance_subnet_ids = module.vpc.public_subnet_ids

  instance_type             = var.instance_type
  iam_instance_profile_name = aws_iam_instance_profile.profile.name
  key_name                  = aws_key_pair.this.key_name
  allowed_ssh_cidr          = var.allowed_ssh_cidr

  min_size         = var.asg_min
  max_size         = var.asg_max
  desired_capacity = var.asg_desired

  health_check_path = var.health_check_path

  tags = local.tags
}
