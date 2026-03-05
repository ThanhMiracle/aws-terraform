output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "security_group_id" {
  value = aws_security_group.this.id
}

# Secrets Manager secret ARN for the master user password
output "master_user_secret_arn" {
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  description = "Secrets Manager secret ARN created by RDS (manage_master_user_password=true)"
}

output "master_username" { 
  value = aws_db_instance.this.username 
}