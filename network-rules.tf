resource "aws_security_group_rule" "private_from_alb_http" {
  type                     = "ingress"
  security_group_id        = module.ec2_private.security_group_id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.alb_security_group_id
  description              = "Allow HTTP from ALB"
}
