resource "aws_s3_bucket" "bucket" {
  bucket        = local.name_with_prefix
  force_destroy = true

  tags = merge(var.tags, {
    Name : var.bucket_name
  })
}
