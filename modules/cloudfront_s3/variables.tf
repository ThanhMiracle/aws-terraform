variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# S3 origin inputs
variable "bucket_id" {
  description = "S3 bucket ID (name) for aws_s3_bucket_policy"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name (origin)"
  type        = string
}

# Optional: custom domain
variable "aliases" {
  type    = list(string)
  default = []
}

# Optional: ACM cert ARN (must be in us-east-1 for CloudFront)
variable "acm_certificate_arn" {
  type    = string
  default = null
}

# Cache / price knobs
variable "price_class" {
  type    = string
  default = "PriceClass_200"
}

# Optional: enable IPv6
variable "is_ipv6_enabled" {
  type    = bool
  default = true
}