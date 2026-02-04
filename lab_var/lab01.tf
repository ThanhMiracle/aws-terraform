locals {
  lab01 = {
    environment = "lab01"

    vpc = {
      cidr = "10.0.0.0/16"

      public_subnets = [
        "10.0.1.0/24",
        "10.0.2.0/24",
        "10.0.3.0/24",
      ]

      private_subnets = [
        "10.0.10.0/24",
        "10.0.20.0/24",
        "10.0.30.0/24",
      ]
    }

    ec2 = {
      instance_type  = "t3.micro"
      ami_id         = null
      attach_deny_s3 = true
      # ssh_cidr_blocks = ["x.x.x.x/32"]  # optional (root can override)
    }

    ec2_user_data = <<-EOF
      #!/bin/bash
      set -e
      apt-get update -y
      apt-get install -y awscli
      aws --version > /var/log/awscli-version.txt
    EOF
  }
}
