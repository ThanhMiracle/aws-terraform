variable "ami_id" {
  type        = string
  description = "AMI ID (optional). If null, use latest Ubuntu 22.04."
  default     = null
}
variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
}

variable "user_data" {
  type        = string
  description = "User data script"
  default     = null
}


variable "vpc_id" {
  type = string
}
variable "ssh_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to EC2"
  default     = ["0.0.0.0/0"]
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name to attach to the EC2 instance"
  default     = null
}


variable "ssh_source_sg_id" {
  type        = string
  description = "Security group ID allowed to SSH to this instance (bastion). If set, CIDR SSH can be empty."
  default     = null
}
