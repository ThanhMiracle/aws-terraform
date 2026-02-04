variable "name" {
  type        = string
  description = "Name tag for the EBS volume"
}

variable "availability_zone" {
  type        = string
  description = "AZ where the EBS volume will be created"
}

variable "size" {
  type        = number
  description = "Size of the EBS volume in GB"
}

variable "type" {
  type    = string
  default = "gp3"
}

variable "instance_id" {
  type        = string
  description = "EC2 instance ID to attach the volume to"
}

variable "device_name" {
  type        = string
  description = "Device name (e.g. /dev/xvdf)"
  default     = "/dev/xvdf"
}

variable "tags" {
  type    = map(string)
  default = {}
}
