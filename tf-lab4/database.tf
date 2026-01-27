############################################
# RDS SG
############################################
resource "aws_security_group" "rds_sg" {
  name   = "lab-rds-sg"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

# Allow Postgres ONLY from ASG instance SG (from modules/alb)
resource "aws_security_group_rule" "rds_postgres_from_asg" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.alb_asg.asg_instance_security_group_id
  description              = "PostgreSQL from ASG instances (ALB module)"
}

resource "aws_security_group_rule" "rds_all_egress" {
  type              = "egress"
  security_group_id = aws_security_group.rds_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}

############################################
# DB Subnet Group (private subnets)
############################################
resource "aws_db_subnet_group" "postgres" {
  name       = "lab-postgres-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids
  tags       = local.tags
}

############################################
# RDS Postgres instance
############################################
resource "aws_db_instance" "postgres" {
  identifier = "lab-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false

  # Lab-friendly (NOT production)
  skip_final_snapshot  = true
  deletion_protection  = false

  tags = local.tags
}
