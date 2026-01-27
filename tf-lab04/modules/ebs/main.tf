resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = var.type

  iops       = var.iops
  throughput = var.throughput

  encrypted  = var.encrypted
  kms_key_id = var.kms_key_id

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_volume_attachment" "this" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.this.id
  instance_id = var.instance_id

  # Optional but often helpful:
  skip_destroy = false
  force_detach = true
}

output "volume_id" {
  value = aws_ebs_volume.this.id
}