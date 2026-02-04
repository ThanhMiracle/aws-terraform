########################################
# Assume role policy for EC2
########################################
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

########################################
# IAM Role
########################################
resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = var.tags
}

########################################
# Allow: list all S3 buckets
########################################
data "aws_iam_policy_document" "allow_list_buckets" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "allow_list_buckets" {
  name   = "AllowListAllBuckets"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.allow_list_buckets.json
}

########################################
# Optional Deny: all S3 actions
########################################
data "aws_iam_policy_document" "deny_all_s3" {
  count = var.deny_all_s3 ? 1 : 0

  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deny_all_s3" {
  count  = var.deny_all_s3 ? 1 : 0
  name   = "DenyAllS3"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.deny_all_s3[0].json
}

########################################
# Instance Profile (EC2 attaches this)
########################################
resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.this.name
}
