variable "key_name" {
  description = "Path to your SSH public key"
  type        = string
  default     = null
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "profile_name" {
  description = "IAM instance profile name for EC2"
  type        = string
  default = null
}

variable "ssh_allowed_ip" {
  description = "Get access only from this IP"
  type = string
}

variable "instance_type" {
    description = "EC2 instance type"
    type        = string
    default     = "t3.micro"
  
}