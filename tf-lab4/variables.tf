variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "key_name" {
  type    = string
  default = null
}

# ✅ Needed for creating aws_key_pair in root (since key_name may be null)
variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# ✅ ASG sizing
variable "asg_desired" {
  type    = number
  default = 1
}

variable "asg_min" {
  type    = number
  default = 1
}

variable "asg_max" {
  type    = number
  default = 4
}

# ✅ ALB health check
variable "health_check_path" {
  type    = string
  default = "/"
}

# DATABASE VARIABLES
variable "db_name" {
  type    = string
  sensitive = true
}

variable "db_username" {
  type    = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

## Docker Variables
variable "jwt_secret" {
  type      = string
  sensitive = true
}
variable "jwt_expire_minutes" {
  type = number
  default = 60
}

variable "minio_access_key" {
  type      = string
  sensitive = true
}

variable "minio_secret_key" {
  type      = string
  sensitive = true
}

variable "minio_bucket" {
  type      = string
  sensitive = true
}