output "from_email_identity" {
  value = aws_ses_email_identity.from.email
}

output "smtp_iam_access_key_id" {
  value = aws_iam_access_key.smtp.id
}

