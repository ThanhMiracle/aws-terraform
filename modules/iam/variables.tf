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
