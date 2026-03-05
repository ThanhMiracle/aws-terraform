output "instance_id" {
  value = aws_instance.this.id
}

output "availability_zone" {
  value = aws_instance.this.availability_zone
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}