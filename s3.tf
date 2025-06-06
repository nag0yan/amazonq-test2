# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.project_name}-flow-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}

# Enable versioning for flow logs bucket
resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure logging for flow logs bucket
resource "aws_s3_bucket_logging" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "flow-logs-access-logs/"
}

# Configure lifecycle policy for flow logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Apply to entire bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# Enable versioning for logs bucket
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle policy for logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Apply to entire bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

# S3 Bucket for static content
resource "aws_s3_bucket" "static" {
  bucket = "${var.project_name}-static-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-static"
  }
}

# S3バケットのバージョニング設定
resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットのパブリックアクセス設定
resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットのライフサイクル設定
resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # バケット全体に適用
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3バケットのアクセスログ設定
resource "aws_s3_bucket_logging" "static" {
  bucket = aws_s3_bucket.static.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "static" {
  bucket     = aws_s3_bucket.static.id
  depends_on = [aws_s3_bucket_public_access_block.static]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.static.arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# S3 bucket for WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket = "${var.project_name}-waf-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-waf-logs"
  }
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Apply to entire bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "waf-logs-access-logs/"
}
