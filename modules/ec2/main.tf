data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (official Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "this" {
  name        = try("${var.tags["Name"]}-sg", null)
  description = "EC2 security group"
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH from CIDRs (bastion use-case)
resource "aws_security_group_rule" "ssh_from_cidrs" {
  count = length(var.ssh_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.this.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  description       = "SSH from allowed CIDRs"
}

# SSH from another SG (private use-case: bastion -> private)
resource "aws_security_group_rule" "ssh_from_sg" {
  count = var.enable_ssh_from_sg ? 1 : 0

  type                     = "ingress"
  description              = "Allow SSH from source security group"
  security_group_id        = aws_security_group.this.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.ssh_source_sg_id

  lifecycle {
    precondition {
      condition     = var.ssh_source_sg_id != null && trimspace(var.ssh_source_sg_id) != ""
      error_message = "ssh_source_sg_id must be set when enable_ssh_from_sg is true."
    }
  }
}


# App port from ALB (or any SG you specify)
resource "aws_security_group_rule" "app_from_sg" {
  for_each = var.enable_app_from_sg ? { "app" = var.allow_app_from_sg_id } : {}

  type                     = "ingress"
  security_group_id        = aws_security_group.this.id
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "App access from ALB security group"
}

resource "aws_instance" "this" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_name

  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data

  tags = var.tags
}