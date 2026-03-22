output "zone_id" {
  description = "Hosted zone ID in use"
  value       = local.zone_id
}

output "zone_name" {
  description = "Hosted zone name"
  value       = var.zone_name
}

output "name_servers" {
  description = "Name servers for created public zone"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}