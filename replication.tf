# S3 cross-region replication role
resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication" {
  name = "${var.project_name}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.flow_logs.arn,
          aws_s3_bucket.logs.arn,
          aws_s3_bucket.static.arn,
          aws_s3_bucket.waf_logs.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.flow_logs.arn}/*",
          "${aws_s3_bucket.logs.arn}/*",
          "${aws_s3_bucket.static.arn}/*",
          "${aws_s3_bucket.waf_logs.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.flow_logs_replica.arn}/*",
          "${aws_s3_bucket.logs_replica.arn}/*",
          "${aws_s3_bucket.static_replica.arn}/*",
          "${aws_s3_bucket.waf_logs_replica.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Replica buckets in a different region
provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

resource "aws_s3_bucket" "flow_logs_replica" {
  provider = aws.replica
  bucket   = "${var.project_name}-flow-logs-replica-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-flow-logs-replica"
  }
}

resource "aws_s3_bucket" "logs_replica" {
  provider = aws.replica
  bucket   = "${var.project_name}-logs-replica-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-logs-replica"
  }
}

resource "aws_s3_bucket" "static_replica" {
  provider = aws.replica
  bucket   = "${var.project_name}-static-replica-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-static-replica"
  }
}

resource "aws_s3_bucket" "waf_logs_replica" {
  provider = aws.replica
  bucket   = "${var.project_name}-waf-logs-replica-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-waf-logs-replica"
  }
}

# Configure replication for each bucket
resource "aws_s3_bucket_replication_configuration" "flow_logs" {
  depends_on = [aws_s3_bucket_versioning.flow_logs]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    id     = "flow-logs-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.flow_logs_replica.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  depends_on = [aws_s3_bucket_versioning.logs]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.logs_replica.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "static" {
  depends_on = [aws_s3_bucket_versioning.static]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "static-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.static_replica.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "waf_logs" {
  depends_on = [aws_s3_bucket_versioning.waf_logs]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "waf-logs-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.waf_logs_replica.arn
      storage_class = "STANDARD"
    }
  }
}

# レプリカバケットのセキュリティ設定
# Versioning
resource "aws_s3_bucket_versioning" "flow_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.flow_logs_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "static_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.static_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "waf_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.waf_logs_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "flow_logs_replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.flow_logs_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs_replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.logs_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "static_replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.static_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "waf_logs_replica" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.waf_logs_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for replica region
resource "aws_kms_key" "s3_encryption_replica" {
  provider                = aws.replica
  description             = "KMS key for S3 bucket encryption in replica region"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-s3-kms-key-replica"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.flow_logs_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.static_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.waf_logs_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.flow_logs_replica.id

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

resource "aws_s3_bucket_lifecycle_configuration" "logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica.id

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

resource "aws_s3_bucket_lifecycle_configuration" "static_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.static_replica.id

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

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.waf_logs_replica.id

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
