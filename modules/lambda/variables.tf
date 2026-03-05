variable "name" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "app.handler"
}

variable "filename" {
  description = "Path to the zipped lambda artifact"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the zip file"
  type        = string
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "vpc_subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "policies" {
  type    = list(string)
  default = []
}

variable "inline_policy_json" {
  type    = string
  default = null
}