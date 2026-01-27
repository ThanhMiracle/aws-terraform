variable "name" {
  description = "Base name for resources"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of 2 public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of 2 private subnet CIDRs"
  type        = list(string)
}

variable "azs" {
  description = "List of 2 availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "ssh_allowed_ip" {
  description = "Your public IP in CIDR notation to allow SSH to bastion (e.g. 203.0.113.10/32)"
  type        = string
}
