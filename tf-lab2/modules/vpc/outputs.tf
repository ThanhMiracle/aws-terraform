#############################################
# modules/vpc/outputs.tf (COMPLETE)
#############################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "private_ec2_sg_id" {
  value = aws_security_group.private_ec2.id
}
