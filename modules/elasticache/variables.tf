variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_sg_ids" {
  type    = list(string)
  default = []
}

variable "engine" {
  type    = string
  default = "valkey"

  validation {
    condition     = contains(["valkey", "redis"], var.engine)
    error_message = "engine must be valkey or redis"
  }
}

variable "engine_version" {
  type = string
}

variable "node_type" {
  type = string
}

variable "port" {
  type    = number
  default = 6379
}

variable "num_node_groups" {
  type    = number
  default = 1
}

variable "replicas_per_node_group" {
  type    = number
  default = 1
}

variable "automatic_failover_enabled" {
  type    = bool
  default = true
}

variable "multi_az_enabled" {
  type    = bool
  default = true
}

variable "at_rest_encryption_enabled" {
  type    = bool
  default = true
}

variable "transit_encryption_enabled" {
  type    = bool
  default = true
}

variable "auth_token" {
  type      = string
  default   = null
  sensitive = true
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "snapshot_retention_limit" {
  type    = number
  default = 7
}

variable "snapshot_window" {
  type    = string
  default = null
}

variable "maintenance_window" {
  type    = string
  default = null
}

variable "parameter_group_family" {
  type = string
}

variable "parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}