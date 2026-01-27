data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  iam_instance_profile        = var.profile_name
  associate_public_ip_address = var.public_ip

  # Attach EC2 key pair by NAME (not file path)
  key_name = var.key_name

  user_data = <<EOF
#!/bin/bash
set -euxo pipefail

dnf -y update
dnf -y install docker
systemctl enable --now docker
usermod -aG docker ec2-user

EOF

  tags = {
    Name = var.name
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.this.availability_zone
  size              = 10
  type              = "gp3"
}

resource "aws_volume_attachment" "attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}
