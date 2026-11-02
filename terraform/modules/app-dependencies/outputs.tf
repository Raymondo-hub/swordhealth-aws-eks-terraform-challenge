output "read_bucket_name" {
  value = aws_s3_bucket.read_only.bucket
}

output "read_bucket_arn" {
  value = aws_s3_bucket.read_only.arn
}

output "write_bucket_name" {
  value = aws_s3_bucket.write_only.bucket
}

output "write_bucket_arn" {
  value = aws_s3_bucket.write_only.arn
}

output "queue_url" {
  value = aws_sqs_queue.this.url
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}
