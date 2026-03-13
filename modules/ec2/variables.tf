variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "iam_instance_profile" {
  type        = string
  default     = null
  description = "Instance profile name to attach to EC2 (from IAM module output)"
}

variable "user_data" {
  type        = string
  default     = null
  description = "User data script (cloud-init/bash) for the instance"
}

# SSH from CIDRs (typically for bastion)
variable "ssh_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed to SSH to this instance"
}

# SSH from a security group (typically bastion -> private)
variable "ssh_source_sg_id" {
  type        = string
  default     = null
  description = "If set, allow SSH from this security group"
}

# Allow app traffic (e.g., ALB -> private EC2)
variable "app_port" {
  type        = number
  default     = 80
  description = "Application port exposed by services on the instance"
}

variable "allow_app_from_sg_id" {
  type        = string
  default     = null
  description = "If set, allow inbound app_port from this security group (e.g., ALB SG)"
}

# Optional: public IP association (true for bastion, false for private)
variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "enable_ssh_from_sg" {
  type    = bool
  default = false

  validation {
    condition     = !var.enable_ssh_from_sg || var.ssh_source_sg_id != null
    error_message = "ssh_source_sg_id must be set when enable_ssh_from_sg is true."
  }
}

variable "enable_app_from_sg" {
  type    = bool
  default = false
}