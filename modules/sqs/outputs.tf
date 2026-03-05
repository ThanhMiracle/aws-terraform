output "queue_name" { value = aws_sqs_queue.this.name }
output "queue_url"  { value = aws_sqs_queue.this.url }
output "queue_arn"  { value = aws_sqs_queue.this.arn }

output "dlq_name" { value = try(aws_sqs_queue.dlq[0].name, null) }
output "dlq_url"  { value = try(aws_sqs_queue.dlq[0].url, null) }
output "dlq_arn"  { value = try(aws_sqs_queue.dlq[0].arn, null) }