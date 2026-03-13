variable "environment" {
  type        = string
  description = "Which environment to deploy to (dev/prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Invalid environment. Allowed values: dev, prod"
  }
}
