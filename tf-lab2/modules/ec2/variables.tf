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

variable "enable_data_volume" {
  type    = bool
  default = false
}

variable "data_device" {
  type    = string
  default = "/dev/nvme1n1"
}

variable "data_mount_path" {
  type    = string
  default = "/data"
}
