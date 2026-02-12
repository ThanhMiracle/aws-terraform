output "lab_name" {
  description = "Current lab name"
  value       = var.lab_file
}

# output "ec2_public_ip" {
#   description = "Public IP of the Lab02 EC2 instance"
#   value       = module.ec2.public_ip
# }

# output "ec2_public_dns" {
#   description = "Public DNS of the Lab02 EC2 instance"
#   value       = module.ec2.public_dns
# }

# output "nginx_url" {
#   description = "URL to access NGINX landing page"
#   value       = "http://${module.ec2.public_ip}"
# }

output "vpc_id" {
  description = "VPC ID created by the VPC module"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}
output "bastion_public_ip" {
  value = module.ec2_public.public_ip
}

output "private_instance_private_ip" {
  value = module.ec2_private.private_ip
}


output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of ALB"
  value       = module.alb.alb_security_group_id
}

output "private_ec2_instance_id" {
  description = "Private EC2 instance ID"
  value       = module.ec2_private.instance_id
}

output "private_ec2_security_group_id" {
  description = "Private EC2 security group ID"
  value       = module.ec2_private.security_group_id
}
# output "lab04_alb_url" {
#   value = "http://${module.asg_alb.alb_dns_name}"
# }
