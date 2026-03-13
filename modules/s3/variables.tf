variable "bucket_name" { type = string }

variable "force_destroy" {
  description = "Set true for labs/dev if you want terraform destroy to remove objects"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Encryption
variable "kms_key_id" {
  description = "Optional KMS key for SSE-KMS; null means SSE-S3 (AES256)"
  type        = string
  default     = null
}

# Versioning
variable "versioning_enabled" {
  type    = bool
  default = false
}

# CORS (for browser uploads, etc.)
variable "cors_enabled" {
  type    = bool
  default = false
}

variable "cors_allowed_origins" {
  type    = list(string)
  default = []
}

variable "cors_allowed_methods" {
  type    = list(string)
  default = ["GET", "PUT", "POST", "HEAD"]
}

variable "cors_allowed_headers" {
  type    = list(string)
  default = ["*"]
}

variable "cors_expose_headers" {
  type    = list(string)
  default = ["ETag"]
}

variable "cors_max_age_seconds" {
  type    = number
  default = 3000
}

# Lifecycle rules
variable "lifecycle_rules" {
  description = "Simple lifecycle rules by prefix"
  type = list(object({
    id                         = string
    status                     = string # Enabled/Disabled
    prefix                     = string
    expiration_days            = number # set null to skip
    noncurrent_expiration_days = number # set null to skip
  }))
  default = []
}

# Bucket policy hook (CloudFront OAC / tight access)
variable "bucket_policy_json" {
  type    = string
  default = null
}
