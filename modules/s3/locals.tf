locals {
  name_with_prefix = "${var.global_variables["project"]}-${var.global_variables["owner"]}-${var.global_variables["environment"]}-${var.bucket_name}"
}
