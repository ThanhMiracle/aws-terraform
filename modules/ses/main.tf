resource "aws_ses_email_identity" "from" {
  email = var.from_email_address
}

# IAM user for SMTP credentials (SES SMTP uses IAM keys)
resource "aws_iam_user" "smtp" {
  name = "${var.name_prefix}-ses-smtp"
  tags = var.tags
}

resource "aws_iam_user_policy" "smtp" {
  name = "${var.name_prefix}-ses-smtp-send"
  user = aws_iam_user.smtp.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "smtp" {
  user = aws_iam_user.smtp.name
}