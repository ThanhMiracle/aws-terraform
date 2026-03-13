locals {
  broker_name = "${var.name_prefix}-rabbitmq"

  secret_name_final = coalesce(var.secret_name, "${var.name_prefix}/mq/rabbitmq")

  # Amazon MQ needs 1 subnet for SINGLE_INSTANCE, 2 subnets for ACTIVE_STANDBY_MULTI_AZ
  selected_subnet_ids = (
    var.deployment_mode == "ACTIVE_STANDBY_MULTI_AZ"
    ? slice(var.private_subnet_ids, 0, 2)
    : slice(var.private_subnet_ids, 0, 1)
  )

  allowed_sg_map = { for idx, sg_id in var.allowed_sg_ids : tostring(idx) => sg_id }

}

########################################
# Validate subnet count (fail fast)
########################################
resource "null_resource" "validate_subnets" {
  triggers = {
    deployment_mode = var.deployment_mode
    subnet_count    = tostring(length(var.private_subnet_ids))
  }

  provisioner "local-exec" {
    command = <<EOT
if [ "${var.deployment_mode}" = "ACTIVE_STANDBY_MULTI_AZ" ] && [ ${length(var.private_subnet_ids)} -lt 2 ]; then
  >&2 echo "ERROR: ACTIVE_STANDBY_MULTI_AZ requires at least 2 private_subnet_ids"
  exit 1
fi
if [ "${var.deployment_mode}" = "SINGLE_INSTANCE" ] && [ ${length(var.private_subnet_ids)} -lt 1 ]; then
  >&2 echo "ERROR: SINGLE_INSTANCE requires at least 1 private_subnet_ids"
  exit 1
fi
exit 0
EOT
  }
}

########################################
# Security Group for MQ
########################################
resource "aws_security_group" "mq" {
  name        = "${local.broker_name}-sg"
  description = "Amazon MQ RabbitMQ SG"
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AMQP
resource "aws_security_group_rule" "amqp_from_allowed_sgs" {
  for_each = local.allowed_sg_map

  type                     = "ingress"
  security_group_id        = aws_security_group.mq.id
  from_port                = 5672
  to_port                  = 5672
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow AMQP from allowed SGs"
}


# AMQPS
resource "aws_security_group_rule" "amqps_from_allowed_sgs" {
  for_each = local.allowed_sg_map

  type                     = "ingress"
  security_group_id        = aws_security_group.mq.id
  from_port                = 5671
  to_port                  = 5671
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow AMQPS from allowed SGs"
}

# Optional management ports
resource "aws_security_group_rule" "mgmt_from_allowed_sgs" {
  for_each = var.enable_management_ingress ? toset(var.allowed_sg_ids) : toset([])

  type                     = "ingress"
  security_group_id        = aws_security_group.mq.id
  from_port                = var.mgmt_port
  to_port                  = var.mgmt_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow RabbitMQ management (HTTP) from allowed SG"
}

resource "aws_security_group_rule" "mgmt_tls_from_allowed_sgs" {
  for_each = var.enable_management_ingress ? toset(var.allowed_sg_ids) : toset([])

  type                     = "ingress"
  security_group_id        = aws_security_group.mq.id
  from_port                = var.mgmt_tls_port
  to_port                  = var.mgmt_tls_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow RabbitMQ management (HTTPS) from allowed SG"
}

########################################
# Password (generate if not provided)
########################################
resource "random_password" "mq" {
  count   = var.password == null ? 1 : 0
  length  = 24
  special = true

  # Avoid characters Amazon MQ rejects: , : = [ ]
  override_special = "!@#$%^&*()-_+."
}

locals {
  mq_password = coalesce(var.password, try(random_password.mq[0].result, null))
}

########################################
# Secrets Manager (store credentials)
########################################
resource "aws_secretsmanager_secret" "mq" {
  name                    = local.secret_name_final
  description             = "Amazon MQ RabbitMQ credentials"
  recovery_window_in_days = var.recovery_window_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "mq" {
  secret_id = aws_secretsmanager_secret.mq.id
  secret_string = jsonencode({
    username = var.username
    password = local.mq_password
  })
}

########################################
# Amazon MQ Broker (RabbitMQ)
########################################
resource "aws_mq_broker" "this" {
  broker_name         = local.broker_name
  engine_type         = "RabbitMQ"
  engine_version      = var.engine_version
  host_instance_type  = var.host_instance_type
  deployment_mode     = var.deployment_mode
  publicly_accessible = var.publicly_accessible
  apply_immediately   = var.apply_immediately

  subnet_ids                 = local.selected_subnet_ids
  security_groups            = [aws_security_group.mq.id]
  auto_minor_version_upgrade = true
  user {
    username = var.username
    password = local.mq_password
  }

  tags = var.tags

  depends_on = [null_resource.validate_subnets]
}