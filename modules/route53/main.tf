locals {
  create_private_zone = var.create_zone && var.private_zone
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name = var.zone_name

  dynamic "vpc" {
    for_each = local.create_private_zone ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-route53-zone"
  })

  lifecycle {
    precondition {
      condition     = !var.private_zone || (var.vpc_id != null && trimspace(var.vpc_id) != "")
      error_message = "vpc_id is required when private_zone = true."
    }
  }
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.existing_zone_id

  record_map = {
    for r in var.records :
    "${r.name}-${r.type}" => r
  }
}

resource "aws_route53_record" "this" {
  for_each = local.record_map

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type

  ttl     = try(each.value.alias, null) == null ? try(each.value.ttl, 300) : null
  records = try(each.value.alias, null) == null ? try(each.value.records, []) : null

  dynamic "alias" {
    for_each = try(each.value.alias, null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = try(alias.value.evaluate_target_health, true)
    }
  }

  allow_overwrite = true
}