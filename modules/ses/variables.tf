variable "name_prefix" { type = string }
variable "tags" { 
    type = map(string)
    default = {} 
}

variable "from_email_address" {
  type        = string
  description = "The email address you will send FROM (must be verified in SES)"
}