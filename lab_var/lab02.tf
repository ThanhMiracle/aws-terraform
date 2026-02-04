locals {
  lab02 = {
    environment = "lab02"

    vpc = {
      cidr         = "10.20.0.0/16"
      subnet_count = 2 # 👈 THIS is number of subnet

      public_subnets = [
        "10.20.1.0/24",
        "10.20.2.0/24",
        "10.20.3.0/24",
      ]

      private_subnets = [
        "10.20.10.0/24",
        "10.20.20.0/24",
        "10.20.30.0/24",
      ]
    }

    ec2 = {
      instance_type = "t2.micro"
      ami_id        = null
    }

    ec2_user_data = <<-EOF
  #!/bin/bash
  set -euo pipefail

  apt-get update -y
  apt-get install -y awscli nginx nvme-cli

  # --- NGINX landing page ---
  cat >/var/www/html/index.html <<'HTML'
  <!doctype html>
  <html>
    <head><title>Lab02 - NGINX</title></head>
    <body style="font-family: Arial;">
      <h1>✅ Lab02 NGINX is running!</h1>
      <p>EBS will be mounted at /mountedvolume</p>
    </body>
  </html>
  HTML
  systemctl enable nginx
  systemctl restart nginx
EOF

  }
}
