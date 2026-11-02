data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "read_only" {
  bucket_prefix = "${var.name}-${data.aws_caller_identity.current.account_id}-read-"
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket" "write_only" {
  bucket_prefix = "${var.name}-${data.aws_caller_identity.current.account_id}-write-"
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "read_only" {
  bucket                  = aws_s3_bucket.read_only.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "write_only" {
  bucket                  = aws_s3_bucket.write_only.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "read_only" {
  bucket = aws_s3_bucket.read_only.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "write_only" {
  bucket = aws_s3_bucket.write_only.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "read_only" {
  bucket = aws_s3_bucket.read_only.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "write_only" {
  bucket = aws_s3_bucket.write_only.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "this" {
  name                       = "${var.name}-application"
  visibility_timeout_seconds = var.queue_visibility_timeout_seconds
  message_retention_seconds  = var.queue_message_retention_seconds
  sqs_managed_sse_enabled    = true
  tags                       = var.tags
}
