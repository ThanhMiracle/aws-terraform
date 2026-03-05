locals {
  # data loaded from lab_var module
  configuration             = module.vars.configuration
  global_variables          = module.vars.global_variables
  global_tags               = module.vars.tags
  my_public_ip_cidr         = "${chomp(data.http.my_ip.response_body)}/32"
  effective_ssh_cidr_blocks = coalesce(var.ssh_cidr_blocks, [local.my_public_ip_cidr])
  # tags used for resources/modules
  vpc_tags = merge(module.tagging.tags, { Component = "vpc" })
  ec2_tags = merge(module.tagging.tags, { Component = "ec2" })

  user_data_rendered = templatefile(
    local.configuration.user_data.template_path,
    {
      app_dir        = local.configuration.user_data.app_dir
      install_docker = file(local.configuration.user_data.parts.install_docker)
    }
  )
}


# lab_var/lab01.tf
#         │
#         ▼
# object (template_path, parts, app_dir)
#         │
#         ▼
# templatefile() + file()
#         │
#         ▼
# string user_data script
#         │
#         ▼
# EC2 instance