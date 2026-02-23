############################
# Networking
############################
resource "aws_db_subnet_group" "this" {
  name       = "pg-subnets-${var.db_identifier}"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name_prefix = "pg-sg-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from allowed SGs"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "pg-sg-${var.db_identifier}" })
}

############################
# RDS PostgreSQL
############################
resource "aws_db_instance" "this" {
  identifier = "pg-${var.db_identifier}"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage_gb

  # NOTE:
  # - db_name phải hợp lệ (không dấu '-', không bắt đầu bằng số, v.v.)
  # - identifier có thể chứa '-'
  db_name  = var.db_name
  username = var.username
  port     = var.port

  # AWS generates + stores master password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  publicly_accessible = false # EC2 trong VPC thì nên private RDS

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection

  apply_immediately   = var.apply_immediately
  skip_final_snapshot = var.skip_final_snapshot

  # Recommended baseline
  storage_encrypted = true

  tags = merge(var.tags, { Name = "pg-${var.db_identifier}" })
}

############################
# Outputs (để EC2/app dùng)
############################
