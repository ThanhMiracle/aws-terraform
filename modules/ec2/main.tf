data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (official Ubuntu publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "ssh" {
  name_prefix = "ec2-sg-"
  vpc_id      = var.vpc_id

  # HTTP open to the internet (lab-friendly)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from CIDR (public instance use-case)
  dynamic "ingress" {
    for_each = (var.ssh_source_sg_id == null && length(var.ssh_cidr_blocks) > 0) ? [1] : []
    content {
      description = "SSH from CIDR"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  # SSH from another Security Group (private instance use-case)
  dynamic "ingress" {
    for_each = (var.ssh_source_sg_id != null) ? [1] : []
    content {
      description     = "SSH from bastion SG"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [var.ssh_source_sg_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "ec2-sg" })
}

resource "aws_instance" "this" {
  ami                  = coalesce(var.ami_id, data.aws_ami.ubuntu_2204.id)
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  key_name             = var.key_name
  iam_instance_profile = var.iam_instance_profile

  user_data              = var.user_data
  user_data_replace_on_change  = true
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = merge(var.tags, { Name = "lab-ec2" })
}
