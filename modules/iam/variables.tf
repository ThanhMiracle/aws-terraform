variable "name_prefix" {
  type        = string
  description = "Prefix for IAM role and instance profile names"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "deny_all_s3" {
  type        = bool
  description = "Whether to attach an explicit Deny s3:* policy"
  default     = false
}

variable "secret_arns" {
  description = "List of Secrets Manager secret ARNs the EC2 role is allowed to read"
  type        = list(string)
  default     = []
}

variable "allow_rds_describe" { 
  type        = bool
  description = "Whether to allow rds:Describe* actions (for troubleshooting)"
  default     = false
}
