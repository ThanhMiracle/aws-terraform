########################################
# ROOT OUTPUTS
########################################

output "lab_name" {
  description = "Current lab name"
  value       = try(local.configuration.environment, var.lab_file)
}

output "environment" {
  description = "Environment name from selected lab configuration"
  value       = local.configuration.environment
}

########################################
# VPC
########################################

output "vpc_id" {
  description = "VPC ID created by the VPC module"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

########################################
# RDS
########################################

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "rds_db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "rds_master_username" {
  description = "RDS master username"
  value       = module.rds.master_username
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS master user secret"
  value       = try(module.rds.master_user_secret_arn, null)
}

########################################
# S3
########################################

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = module.s3.bucket_id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = module.s3.bucket_regional_domain_name
}

########################################
# MQ (RabbitMQ)
########################################

output "mq_broker_id" {
  description = "Amazon MQ broker ID"
  value       = module.mq.broker_id
}

output "mq_broker_arn" {
  description = "Amazon MQ broker ARN"
  value       = module.mq.broker_arn
}

output "mq_secret_arn" {
  description = "Secrets Manager ARN holding MQ credentials"
  value       = module.mq.secret_arn
}

output "mq_endpoints" {
  description = "MQ endpoints"
  value       = module.mq.endpoints
}

output "mq_console_url" {
  description = "RabbitMQ console URL (if provided by AWS)"
  value       = module.mq.console_url
}

########################################
# SES
########################################

output "ses_from_email_identity" {
  description = "SES verified FROM email identity"
  value       = module.ses.from_email_identity
}

output "ses_smtp_iam_access_key_id" {
  description = "IAM access key id used to generate SES SMTP credentials"
  value       = module.ses.smtp_iam_access_key_id
}

########################################
# App Secrets
########################################

output "app_secrets_arn" {
  description = "Secrets Manager ARN for app secrets"
  value       = module.app_secrets.arn
}


########################################
# IAM
########################################

output "iam_role_name" {
  description = "IAM role name"
  value       = module.iam.role_name
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = module.iam.instance_profile_name
}

########################################
# EC2
########################################

output "bastion_public_ip" {
  description = "Public IP of bastion host (ec2_public)"
  value       = module.ec2_public.public_ip
}

output "app_private_instance_private_ip" {
  description = "Private IP of private application EC2"
  value       = module.ec2_private.private_ip
}

########################################
# Application Load Balancer
########################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.lb.dns_name
}

output "app_url" {
  description = "URL to access the application"
  value       = "http://${module.lb.dns_name}"
}


########################################
# CloudFront CDN
########################################

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront_s3.domain_name
}

output "images_cdn_url" {
  description = "Base URL for product images"
  value       = "https://${module.cloudfront_s3.domain_name}"
}