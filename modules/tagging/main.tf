locals {

  default_tags = {
    Region        = data.aws_region.current.id
    Environment   = var.environment
    Owner         = var.owner
    Project       = var.project
    ProvisionedBy = var.provisioned_by
  }

  default_tags_map = {
    for item in keys(local.default_tags) :
    item => local.default_tags[item]
    if local.default_tags[item] != null
  }

  tags = merge(local.default_tags_map)
}