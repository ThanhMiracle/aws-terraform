variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "db_name" { type = string }
variable "engine" { type = string }
# variable "password" {
#   type      = string
#   sensitive = true
# }
variable "username" { type = string }
variable "engine_version" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage_gb" { type = number }
variable "port" { type = number }

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Security groups allowed to connect to Postgres"
}

variable "db_identifier" {
  description = "RDS identifier suffix (can include '-')"
  type        = string
}

variable "publicly_accessible" { type = bool }
variable "multi_az" { type = bool }
variable "backup_retention_days" { type = number }
variable "deletion_protection" { type = bool }
variable "tags" { type = map(string) }
variable "apply_immediately" { type = bool }
variable "skip_final_snapshot" { type = bool }