variable "name" {
  type        = string
  description = "Base name for ALB resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB (usually 2+ in different AZs)"
}

variable "target_instance_id" {
  type        = string
  description = "EC2 instance ID to register in the target group"
}

variable "target_port" {
  type        = number
  description = "Port on the instance the app listens on"
  default     = 80
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access ALB"
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources"
  default     = {}
}
