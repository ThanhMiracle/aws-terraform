resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = each.key
  type        = each.value.type
  value       = each.value.value
  description = try(each.value.description, null)
  tier        = try(each.value.tier, "Standard")
  overwrite   = try(each.value.overwrite, true)
  key_id      = try(each.value.kms_key_id, null)

  tags = merge(
    var.common_tags,
    try(each.value.tags, {})
  )
}