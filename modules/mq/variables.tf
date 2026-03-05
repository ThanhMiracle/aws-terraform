variable "name_prefix" {
  type        = string
  description = "Prefix for naming (e.g., lab01)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the broker"
}

variable "allowed_sg_ids" {
  type        = list(string)
  default     = []
  description = "Security group IDs allowed to connect to RabbitMQ ports"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# RabbitMQ settings
variable "engine_version" {
  type        = string
  default     = "3.13"
  description = "RabbitMQ engine version (must be supported by Amazon MQ)"
}

variable "deployment_mode" {
  type        = string
  default     = "SINGLE_INSTANCE"
  description = "SINGLE_INSTANCE or ACTIVE_STANDBY_MULTI_AZ"
  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ"], var.deployment_mode)
    error_message = "deployment_mode must be SINGLE_INSTANCE or ACTIVE_STANDBY_MULTI_AZ"
  }
}

variable "host_instance_type" {
  type        = string
  default     = "mq.t3.micro"
  description = "Broker instance type"
}

# Ports
variable "amqp_port" {
  type    = number
  default = 5672
}

variable "amqps_port" {
  type    = number
  default = 5671
}

variable "mgmt_port" {
  type    = number
  default = 15672
}

variable "mgmt_tls_port" {
  type    = number
  default = 15671
}

variable "enable_management_ingress" {
  type        = bool
  default     = false
  description = "If true, allow management ports from allowed_sg_ids (15672/15671)"
}

# Credentials
variable "username" {
  type        = string
  default     = "appadmin"
  description = "RabbitMQ admin username"
}

variable "password" {
  type        = string
  default     = null
  description = "If null, module generates a random password"
  sensitive   = true
}

# Secrets Manager
variable "secret_name" {
  type        = string
  default     = null
  description = "Secrets Manager name. If null, defaults to <name_prefix>/mq/rabbitmq"
}

variable "recovery_window_days" {
  type    = number
  default = 0
}

# Broker behavior
variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "apply_immediately" {
  type    = bool
  default = true
}