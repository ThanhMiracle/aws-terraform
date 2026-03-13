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
  enable_s3_product_image_upload = (
    var.enable_product_image_upload &&
    var.s3_bucket_arn != null &&
    trimspace(var.s3_bucket_arn) != ""
  )

  enable_secrets_access = (
    var.enable_secrets_read &&
    length(var.secret_arns) > 0
  )

  create_combined_policy = (
    var.allow_list_all_buckets ||
    local.enable_s3_product_image_upload ||
    var.allow_rds_describe ||
    var.enable_ses_send ||
    local.enable_secrets_access
  )
}

data "aws_iam_policy_document" "combined" {
  count = local.create_combined_policy ? 1 : 0

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
  # S3: product images (only when enabled)
  ########################################

  # Allow listing only the products/ prefix
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

  # Allow object operations under products/
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

  # Allow bucket-level operations needed by SDKs / multipart uploads
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
  # Secrets Manager (only when enabled)
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
  # RDS describe (optional)
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
  # SES send email (optional)
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
  count  = local.create_combined_policy ? 1 : 0
  name   = "${var.name_prefix}-combined"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.combined[0].json
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