locals {
  lab04 = {
    environment = "lab04"

    vpc = {
      cidr         = "10.40.0.0/16"
      subnet_count = 2

      public_subnets  = ["10.40.1.0/24", "10.40.2.0/24"]
      private_subnets = ["10.40.101.0/24", "10.40.102.0/24"]
    }

    asg_alb = {
      instance_type = "t3.micro"
      ami_id        = null

      min_size         = 2
      max_size         = 4
      desired_capacity = 2

      alb_listener_port = 80
      target_port       = 80
      health_check_path = "/"
    }

    user_data = <<-EOF
      #!/bin/bash
      set -e
      apt-get update -y
      apt-get install -y nginx
      echo "hello from ASG instance: $(hostname)" > /var/www/html/index.html
      systemctl enable nginx
      systemctl restart nginx
    EOF
  }
}
