locals {
  # Selected environment data from ./lab_var
  configuration    = module.vars.configuration
  global_variables = module.vars.global_variables
  global_tags      = module.vars.tags

  # Environment name
  environment = local.configuration.environment

  # SSH defaults
  my_public_ip_cidr         = "${chomp(data.http.my_ip.response_body)}/32"
  effective_ssh_cidr_blocks = coalesce(var.ssh_cidr_blocks, [local.my_public_ip_cidr])

  # Standardized base tags from tagging module
  base_tags = module.tagging.tags

  # Component-specific tags
  vpc_tags         = merge(local.base_tags, { Component = "vpc" })
  ec2_tags         = merge(local.base_tags, { Component = "ec2" })
  s3_tags          = merge(local.base_tags, { Component = "s3" })
  iam_tags         = merge(local.base_tags, { Component = "iam" })
  alb_tags         = merge(local.base_tags, { Component = "alb" })
  rds_tags         = merge(local.base_tags, { Component = "rds" })
  mq_tags          = merge(local.base_tags, { Component = "mq" })
  ses_tags         = merge(local.base_tags, { Component = "ses" })
  secrets_tags     = merge(local.base_tags, { Component = "secrets" })
  elasticache_tags = merge(local.base_tags, { Component = "elasticache" })

  # Rendered user_data for private EC2
  user_data_rendered = templatefile(
    local.configuration.user_data.template_path,
    {
      app_dir        = local.configuration.user_data.app_dir
      install_docker = file(local.configuration.user_data.parts.install_docker)
    }
  )
}