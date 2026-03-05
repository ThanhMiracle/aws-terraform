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
  # Only needed if you use a customer-managed KMS key for Secrets Manager.
  secret_arn_patterns_for_kms = length(var.secret_arns) > 0 ? [for a in var.secret_arns : "${a}*"] : []

  # A single switch to decide whether we create a combined policy at all
  create_combined_policy = (
    var.allow_list_all_buckets ||
    var.deny_all_s3 ||
    var.allow_rds_describe ||
    (var.enable_secrets_read && length(var.secret_arns) > 0) ||
    (var.kms_key_arn != null && var.kms_key_arn != "")
  )
}

data "aws_iam_policy_document" "combined" {
  count = local.create_combined_policy ? 1 : 0

  # Allow: list buckets (rarely needed)
  dynamic "statement" {
    for_each = var.enable_product_image_upload ? [1] : []
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
        values   = [
          "products/*",
          "products"
        ]
      }
    }
  }
  # Allow product-service (EC2 role) to upload/delete product images in S3
  dynamic "statement" {
    for_each = var.enable_product_image_upload ? [1] : []
    content {
      effect = "Allow"

      actions = [
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

  # Some SDK operations require bucket-level permissions
  dynamic "statement" {
    for_each = var.enable_product_image_upload ? [1] : []
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

  # Allow: read Secrets Manager secrets
  dynamic "statement" {
    for_each = (var.enable_secrets_read && length(var.secret_arns) > 0) ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = var.secret_arns
    }
  }

  # Allow: describe RDS instances
  dynamic "statement" {
    for_each = var.allow_rds_describe ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["rds:DescribeDBInstances"]
      resources = ["*"]
    }
  }

  # Allow: KMS decrypt for secrets (only if kms_key_arn provided AND you are reading secrets)
  dynamic "statement" {
    for_each = (
      (var.kms_key_arn != null && var.kms_key_arn != "") &&
      (var.enable_secrets_read && length(var.secret_arns) > 0)
    ) ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [var.kms_key_arn]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
      }

      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:secretsmanager:arn"
        values   = local.secret_arn_patterns_for_kms
      }
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