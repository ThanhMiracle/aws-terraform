locals {
  labs = {
    lab01 = local.lab01
    lab02 = local.lab02
    # lab03 = local.lab03
    lab04 = local.lab04
  }

  selected = local.labs[var.lab_file]

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
