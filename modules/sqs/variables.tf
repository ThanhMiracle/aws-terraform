variable "name_prefix" { type = string }
variable "name"        { type = string }
variable "tags"        { 
  type = map(string)
  default = {} 
}

variable "fifo" {
  type    = bool
  default = false
}

variable "content_based_deduplication" {
  type    = bool
  default = true
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "message_retention_seconds" {
  type    = number
  default = 345600
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 0
}

variable "delay_seconds" {
  type    = number
  default = 0
}

variable "max_message_size" {
  type    = number
  default = 262144
}

variable "sse_enabled" {
  type    = bool
  default = true
}

variable "kms_master_key_id" {
  type    = string
  default = null
}

variable "enable_dlq" {
  type    = bool
  default = true
}

variable "dlq_max_receive_count" {
  type    = number
  default = 5
}