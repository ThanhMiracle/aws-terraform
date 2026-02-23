output "db_name" { value = aws_db_instance.this.db_name }
output "security_group_id" { value = aws_security_group.this.id }

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for RDS master user (only when manage_master_user_password=true)"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}