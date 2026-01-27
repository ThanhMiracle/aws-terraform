variable "name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "size" {
  type = number
}

variable "type" {
  type    = string
  default = "gp3"
}

variable "iops" {
  type    = number
  default = null
}

variable "throughput" {
  type    = number
  default = null
}

variable "encrypted" {
  type    = bool
  default = true
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "instance_id" {
  type = string
}

variable "device_name" {
  type    = string
  default = "/dev/xvdf"
}
