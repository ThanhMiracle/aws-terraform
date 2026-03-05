locals {
  queue_name = var.fifo ? "${var.name_prefix}-${var.name}.fifo" : "${var.name_prefix}-${var.name}"
  dlq_name   = var.fifo ? "${var.name_prefix}-${var.name}-dlq.fifo" : "${var.name_prefix}-${var.name}-dlq"
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                        = local.dlq_name
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo ? var.content_based_deduplication : null

  sqs_managed_sse_enabled = var.sse_enabled && var.kms_master_key_id == null
  kms_master_key_id       = var.kms_master_key_id

  message_retention_seconds = var.message_retention_seconds

  tags = var.tags
}

resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo ? var.content_based_deduplication : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size

  sqs_managed_sse_enabled = var.sse_enabled && var.kms_master_key_id == null
  kms_master_key_id       = var.kms_master_key_id

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  tags = var.tags
}