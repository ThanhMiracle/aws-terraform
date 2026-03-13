locals {
  environments = {
    dev  = local.dev
    prod = local.prod
  }

  selected = local.environments[var.environment]

  merged_global_variables = merge(
    local.global_variables,
    { environment = local.selected.environment }
  )

  merged_tags = merge(
    local.tags,
    { environment = local.selected.environment }
  )
}

output "configuration" {
  value = local.selected
}

output "global_variables" {
  value = local.merged_global_variables
}

output "tags" {
  value = local.merged_tags
}