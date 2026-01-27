output "alb_dns_name" {
  value = module.alb_asg.alb_dns_name
}

output "asg_instance_security_group_id" {
  value = module.alb_asg.asg_instance_security_group_id
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.address
}

output "postgres_port" {
  value = aws_db_instance.postgres.port
}

output "product_images_bucket" {
  value = aws_s3_bucket.product_images.bucket
}
