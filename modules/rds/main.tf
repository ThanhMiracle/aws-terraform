locals {
  allowed_sg_map = { for idx, sg_id in var.allowed_sg_ids : tostring(idx) => sg_id }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.db_identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.db_identifier}-rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress_from_allowed_sgs" {
  for_each = local.allowed_sg_map

  type                     = "ingress"
  security_group_id        = aws_security_group.this.id
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow DB access from allowed security group"
}

resource "aws_db_instance" "this" {
  identifier = var.db_identifier

  engine         = var.engine
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage_gb
  storage_type      = var.storage_type

  db_name  = var.db_name
  username = var.username
  port     = var.port

  # ✅ store master password in Secrets Manager automatically
  manage_master_user_password = true
  # optional: use your own KMS key for the RDS-managed secret
  # master_user_secret_kms_key_id = aws_kms_key.rds_secret.arn

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  publicly_accessible     = var.publicly_accessible
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = var.apply_immediately

  storage_encrypted = true

  tags = var.tags
}