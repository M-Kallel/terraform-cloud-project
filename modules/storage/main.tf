data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.prefix}-${data.aws_caller_identity.current.account_id}-app"
}

removed {
  from = aws_s3_bucket.app

  lifecycle {
    destroy = false
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = local.bucket_name
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = local.bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = local.bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket     = local.bucket_name
  depends_on = [aws_s3_bucket_versioning.app]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}