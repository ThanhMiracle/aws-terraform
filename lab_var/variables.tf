variable "lab_file" {
  type        = string
  description = "Which lab config to run (lab01/lab02/lab03/lab04)"
  default     = "lab01"

  validation {
    condition     = contains(["lab01", "lab02", "lab03", "lab04", "lab05"], var.lab_file)
    error_message = "Invalid lab_file. Allowed values: lab01, lab02, lab03, lab04, lab05"
  }
}
