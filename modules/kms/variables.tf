variable "description" {
  type = string
}

variable "alias" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "deletion_window_in_days" {
  type    = number
  default = 7
}