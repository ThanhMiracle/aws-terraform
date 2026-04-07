variable "parameters" {
  description = "Map of SSM parameters to create"
  type = map(object({
    type        = string
    value       = string
    description = optional(string)
    tier        = optional(string, "Standard")
    overwrite   = optional(bool, true)
    kms_key_id  = optional(string)
    tags        = optional(map(string), {})
  }))
}

variable "common_tags" {
  description = "Common tags applied to all parameters"
  type        = map(string)
  default     = {}
}