variable "name_prefix" {
  type        = string
  description = "Prefix for secret name, e.g. env/project"
}

variable "secret_name" {
  type        = string
  description = "Secret short name, e.g. microshop/app"
}

variable "description" {
  type        = string
  default     = null
  description = "Optional secret description"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to the secret"
}

variable "secret_data" {
  type        = map(string)
  description = "Key/value pairs stored as JSON in Secrets Manager"
  sensitive   = true
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional customer-managed KMS key ARN for encrypting the secret"
}

variable "recovery_window_in_days" {
  type        = number
  default     = 7
  description = "Recovery window for deletion (0-30). Use 0 only for labs."
}