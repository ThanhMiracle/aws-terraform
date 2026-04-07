variable "name_prefix" {
  type = string
}

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
  description = "List of Secrets Manager secret ARNs the role can read."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN, if secret decryption permissions are later needed."
  type        = string
  default     = null
}

variable "allow_rds_describe" {
  description = "Whether to allow describing RDS DB instances."
  type        = bool
  default     = false
}

variable "allow_list_all_buckets" {
  description = "Whether to allow s3:ListAllMyBuckets."
  type        = bool
  default     = false
}

variable "deny_all_s3" {
  description = "Reserved for future use. Not currently used in main.tf."
  type        = bool
  default     = false
}

variable "inline_policy_json" {
  description = "Optional JSON policy document to attach as an inline policy to the IAM role."
  type        = string
  default     = null
}

variable "enable_secrets_read" {
  description = "Whether to attach Secrets Manager read permissions to the role."
  type        = bool
  default     = false
}

variable "s3_bucket_arn" {
  description = "Bucket ARN used for product image upload permissions, for example arn:aws:s3:::my-bucket."
  type        = string
  default     = null
}

variable "enable_product_image_upload" {
  description = "Whether to allow uploading, reading, and deleting objects under products/ in the configured S3 bucket."
  type        = bool
  default     = false
}

variable "enable_ses_send" {
  description = "Whether to allow sending email via Amazon SES."
  type        = bool
  default     = false
}

variable "enable_ssm_parameter_read" {
  type    = bool
  default = false
}

variable "ssm_parameter_arns" {
  type    = list(string)
  default = []
}