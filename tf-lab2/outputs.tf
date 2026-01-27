output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.ec2_bastion.public_ip
}
output "private_subnet_ip" {
  description = "Private IP of the private EC2 instance"
  value       = module.ec2_private.private_ip
}