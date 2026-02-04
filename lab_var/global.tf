locals {
  global_variables = {
    owner   = "thanh"
    project = "aws"
  }

  tags = {
    owner          = local.global_variables.owner
    project        = local.global_variables.project
    provisioned_by = "terraform"
  }
}
