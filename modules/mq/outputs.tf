output "broker_id" {
  value = aws_mq_broker.this.id
}

output "broker_arn" {
  value = aws_mq_broker.this.arn
}

output "security_group_id" {
  value = aws_security_group.mq.id
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.mq.arn
  description = "Secrets Manager ARN holding MQ credentials"
}

output "endpoints" {
  value       = aws_mq_broker.this.instances[*].endpoints
  description = "List of broker endpoints"
}

output "console_url" {
  value       = try(aws_mq_broker.this.instances[0].console_url, null)
  description = "RabbitMQ console URL (if provided by AWS)"
}