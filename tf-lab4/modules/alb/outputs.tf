output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "asg_instance_security_group_id" {
  value = aws_security_group.asg_instance_sg.id
}
