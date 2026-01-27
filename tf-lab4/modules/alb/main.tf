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

locals {
  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "[BOOT] user_data start (Ubuntu 22.04)"

# Update packages
apt-get update -y
apt-get upgrade -y

# Install nginx
apt-get install -y nginx

# Create landing page
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Hello</title>
    <style>
      body {
        margin: 0;
        font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell;
        background: #0f172a;
        color: #e5e7eb;
      }
      .wrap {
        min-height: 100vh;
        display: grid;
        place-items: center;
      }
      .card {
        background: #020617;
        padding: 32px 40px;
        border-radius: 16px;
        box-shadow: 0 20px 40px rgba(0,0,0,.4);
        text-align: center;
      }
      h1 {
        margin: 0 0 8px;
        font-size: 32px;
      }
      p {
        margin: 0;
        color: #94a3b8;
      }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <h1>Hello 👋</h1>
        <p>Nginx is running on Ubuntu 22.04</p>
      </div>
    </div>
  </body>
</html>
HTML

# Enable & start nginx
systemctl enable nginx
systemctl start nginx
systemctl status nginx --no-pager || true

echo "[BOOT] user_data done"
EOF
}



#############################################
# Security Groups
#############################################

resource "aws_security_group" "alb_sg" {
  name   = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet"
}

resource "aws_security_group_rule" "alb_all_egress" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}

resource "aws_security_group" "asg_instance_sg" {
  name   = "${var.name}-instance-sg"
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_security_group_rule" "asg_http_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.asg_instance_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "HTTP from ALB only"
}

resource "aws_security_group_rule" "asg_ssh_from_cidr" {
  type              = "ingress"
  security_group_id = aws_security_group.asg_instance_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  description       = "SSH from allowed CIDR"
}

resource "aws_security_group_rule" "asg_all_egress" {
  type              = "egress"
  security_group_id = aws_security_group.asg_instance_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}

#############################################
# Target Group + ALB + Listener
#############################################

resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.name}-fe-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb" "app_alb" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = var.alb_subnet_ids

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

#############################################
# Launch Template
#############################################
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg_instance_sg.id]
  }

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
# Auto Scaling Group
#############################################
resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.instance_subnet_ids

  target_group_arns = [
    aws_lb_target_group.frontend_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 900

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
