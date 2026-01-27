variable "name" {}
variable "cidr_block" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "azs" { type = list(string) }
variable "tags" { type = map(string) }
