variable "name_prefix" {
  type        = string
  description = "Prefix for ALB resources (e.g., lab01)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "target_instance_id" {
  type        = string
  description = "EC2 instance ID to register in the target group"
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "listener_protocol" {
  type    = string
  default = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], upper(var.listener_protocol))
    error_message = "listener_protocol must be HTTP or HTTPS (case-insensitive)."
  }
}

variable "target_port" {
  type    = number
  default = 80
}

variable "target_protocol" {
  type    = string
  default = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], upper(var.target_protocol))
    error_message = "target_protocol must be HTTP or HTTPS (case-insensitive)."
  }
}

variable "healthcheck_path" {
  type    = string
  default = "/health"
}

variable "healthcheck_matcher" {
  type    = string
  default = "200-399"
}

variable "healthcheck_interval" {
  type    = number
  default = 15
}

variable "healthcheck_timeout" {
  type    = number
  default = 5
}

variable "healthy_threshold" {
  type    = number
  default = 2
}

variable "unhealthy_threshold" {
  type    = number
  default = 3
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the ALB listener"
}

# Optional HTTPS support
variable "certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN (required if listener_protocol=HTTPS)"
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "SSL policy for HTTPS listeners"
}

variable "app_security_group_id" {
  type        = string
  description = "Security group ID of the application (private EC2) to allow ALB -> app traffic"
}

variable "app_port" {
  type        = number
  description = "Port the app listens on"
  default     = 80
}