variable "name" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "sg_ids" { type = list(string) }
variable "profile_name" {}
variable "public_ip" { type = bool }
variable "key_name" {
  description = "EC2 Key Pair name in AWS (NOT a file path)."
  type        = string
  default     = null
}
