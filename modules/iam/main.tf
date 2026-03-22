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
# IAM Role + Instance Profile
########################################
resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  path               = var.iam_path
  tags               = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-profile"
  role = aws_iam_role.this.name
  path = var.iam_path
  tags = var.tags
}

########################################
# Consolidated inline policy
########################################
locals {
  enable_s3_product_image_upload = var.enable_product_image_upload
  enable_secrets_access          = var.enable_secrets_read
}

check "s3_bucket_arn_required" {
  assert {
    condition = (
      !var.enable_product_image_upload ||
      try(trimspace(var.s3_bucket_arn), "") != ""
    )
    error_message = "s3_bucket_arn must be set when enable_product_image_upload is true."
  }
}

check "secret_arns_required" {
  assert {
    condition = (
      !var.enable_secrets_read ||
      length(var.secret_arns) > 0
    )
    error_message = "secret_arns must contain at least one ARN when enable_secrets_read is true."
  }
}

data "aws_iam_policy_document" "combined" {
  ########################################
  # S3: optional list all buckets
  ########################################
  dynamic "statement" {
    for_each = var.allow_list_all_buckets ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets"
      ]
      resources = ["*"]
    }
  }

  ########################################
  # S3: product images
  ########################################
  dynamic "statement" {
    for_each = local.enable_s3_product_image_upload ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ]
      resources = [
        var.s3_bucket_arn
      ]
      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["products", "products/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.enable_s3_product_image_upload ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ]
      resources = [
        "${var.s3_bucket_arn}/products/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = local.enable_s3_product_image_upload ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ]
      resources = [
        var.s3_bucket_arn
      ]
    }
  }

  ########################################
  # Secrets Manager
  ########################################
  dynamic "statement" {
    for_each = local.enable_secrets_access ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = var.secret_arns
    }
  }

  ########################################
  # RDS describe
  ########################################
  dynamic "statement" {
    for_each = var.allow_rds_describe ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "rds:DescribeDBInstances"
      ]
      resources = ["*"]
    }
  }

  ########################################
  # SES send email
  ########################################
  dynamic "statement" {
    for_each = var.enable_ses_send ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail",
        "ses:GetIdentityVerificationAttributes"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "combined" {
  name   = "${var.name_prefix}-combined"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.combined.json
}

########################################
# Optional inline policy JSON (pass-through)
########################################
resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json == null ? 0 : 1
  name   = "${var.name_prefix}-inline"
  role   = aws_iam_role.this.name
  policy = var.inline_policy_json
}