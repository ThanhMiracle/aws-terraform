variable "environment" {
  type        = string
  description = "Environment/profile name"
  default     = null
}

variable "ssh_key_name" {
  type        = string
  description = "EC2 Key Pair name to create/use"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key file (e.g. ~/.ssh/id_ed25519.pub)"
}

variable "ssh_cidr_blocks" {
  type        = list(string)
  description = "CIDRs allowed to SSH. If null, defaults to your current public IP /32."
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = null
}

# Used by module "asm" (kms_key_id can be key id, key ARN, alias, or alias ARN)
variable "kms_key_id" {
  description = "KMS key identifier for Secrets Manager encryption (key id/arn or alias)"
  type        = string
  default     = null
}

