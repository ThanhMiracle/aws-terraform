variable "name_prefix" {
  type = string
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "vpc_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "public_subnets" {
  type = list(string)
  validation {
    condition     = length(var.public_subnets) > 0 && alltrue([for c in var.public_subnets : can(cidrnetmask(c))])
    error_message = "public_subnets must be non-empty and contain valid CIDR blocks."
  }
}

variable "private_subnets" {
  type = list(string)
  validation {
    condition     = length(var.private_subnets) > 0 && alltrue([for c in var.private_subnets : can(cidrnetmask(c))])
    error_message = "private_subnets must be non-empty and contain valid CIDR blocks."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}