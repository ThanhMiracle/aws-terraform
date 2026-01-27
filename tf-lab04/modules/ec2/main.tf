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


resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  iam_instance_profile        = var.profile_name
  associate_public_ip_address = var.public_ip
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    DEVICE=/dev/nvme1n1

    if ! blkid $DEVICE; then
      mkfs.ext4 $DEVICE
    fi

    mkdir -p /data

    if ! mountpoint -q /data; then
      mount $DEVICE /data
    fi

    grep -q "$DEVICE" /etc/fstab || \
      echo "$DEVICE /data ext4 defaults,nofail 0 2" >> /etc/fstab
  EOF

  tags = {
    Name = var.name
  }
}


