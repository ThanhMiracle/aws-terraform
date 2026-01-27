variable "name" { type = string }
variable "aws_region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" { type = string }

variable "alb_subnet_ids" { type = list(string) }

variable "instance_subnet_ids" { type = list(string) }

variable "instance_type" { type = string }

variable "iam_instance_profile_name" { type = string }

variable "key_name" {
  type    = string
  default = null
}

variable "allowed_ssh_cidr" { type = string }

variable "min_size" { type = number }
variable "max_size" { type = number }
variable "desired_capacity" { type = number }

variable "health_check_path" {
  type    = string
  default = "/"
}
