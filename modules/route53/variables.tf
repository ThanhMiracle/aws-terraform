variable "name_prefix" {
  type        = string
  description = "Prefix for naming/tagging"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}

variable "create_zone" {
  type        = bool
  default     = false
  description = "Whether to create the hosted zone"
}

variable "zone_name" {
  type        = string
  description = "Hosted zone name, e.g. example.com"
}

variable "private_zone" {
  type        = bool
  default     = false
  description = "Whether the hosted zone is private"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "VPC ID for private hosted zone"
}

variable "existing_zone_id" {
  type        = string
  default     = null
  description = "Existing hosted zone ID to use when create_zone = false"
}

variable "records" {
  description = "DNS records to create"
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))

    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
  }))
  default = []
}