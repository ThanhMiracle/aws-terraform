variable "name_prefix" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "iam_path" {
  type    = string
  default = "/"
}

variable "aws_region" {
  type    = string
  default = null
}

variable "secret_arns" {
  description = "List of secret ARNs the role can read."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "allow_rds_describe" {
  type    = bool
  default = false
}

variable "allow_list_all_buckets" {
  type    = bool
  default = false
}

variable "deny_all_s3" {
  type    = bool
  default = false
}

variable "inline_policy_json" {
  description = "Optional JSON policy to attach inline to the IAM role/policy in this module."
  type        = string
  default     = null
}

variable "enable_secrets_read" {
  description = "Whether to attach SecretsManager read policy to the role."
  type        = bool
  default     = false
}

variable "s3_bucket_arn" {
  description = "If allow_list_all_buckets is true, restrict to this bucket ARN (e.g. arn:aws:s3:::my-bucket). Required if allow_list_all_buckets is true."
  type        = string
  default     = null
}

variable "enable_product_image_upload" {
  type    = bool
  default = false
}