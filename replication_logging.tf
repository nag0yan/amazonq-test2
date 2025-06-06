# レプリカリージョンのログバケット
resource "aws_s3_bucket" "logs_replica_region" {
  provider = aws.replica
  bucket   = "${var.project_name}-logs-replica-region-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-logs-replica-region"
  }
}

resource "aws_s3_bucket_versioning" "logs_replica_region" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica_region.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_replica_region" {
  provider                = aws.replica
  bucket                  = aws_s3_bucket.logs_replica_region.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_replica_region" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica_region.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_replica_region" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica_region.id

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

# レプリカバケットのアクセスログ設定
resource "aws_s3_bucket_logging" "flow_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.flow_logs_replica.id

  target_bucket = aws_s3_bucket.logs_replica_region.id
  target_prefix = "flow-logs-replica-access-logs/"
}

resource "aws_s3_bucket_logging" "logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica.id

  target_bucket = aws_s3_bucket.logs_replica_region.id
  target_prefix = "logs-replica-access-logs/"
}

resource "aws_s3_bucket_logging" "static_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.static_replica.id

  target_bucket = aws_s3_bucket.logs_replica_region.id
  target_prefix = "static-replica-access-logs/"
}

resource "aws_s3_bucket_logging" "waf_logs_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.waf_logs_replica.id

  target_bucket = aws_s3_bucket.logs_replica_region.id
  target_prefix = "waf-logs-replica-access-logs/"
}

# レプリカリージョンのSNSトピック
resource "aws_sns_topic" "s3_notifications_replica" {
  provider          = aws.replica
  name              = "${var.project_name}-s3-notifications-replica"
  kms_master_key_id = aws_kms_key.s3_encryption_replica.arn
}

# レプリカバケットのイベント通知
resource "aws_s3_bucket_notification" "flow_logs_replica_notification" {
  provider = aws.replica
  bucket   = aws_s3_bucket.flow_logs_replica.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications_replica.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

resource "aws_s3_bucket_notification" "logs_replica_notification" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications_replica.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

resource "aws_s3_bucket_notification" "static_replica_notification" {
  provider = aws.replica
  bucket   = aws_s3_bucket.static_replica.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications_replica.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_notification" "waf_logs_replica_notification" {
  provider = aws.replica
  bucket   = aws_s3_bucket.waf_logs_replica.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications_replica.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# レプリカリージョンのログバケットのイベント通知
resource "aws_s3_bucket_notification" "logs_replica_region_notification" {
  provider = aws.replica
  bucket   = aws_s3_bucket.logs_replica_region.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications_replica.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# プライマリリージョンのログバケット (レプリカリージョンのログバケットのレプリケーション先)
resource "aws_s3_bucket" "logs_replica_region_primary" {
  bucket = "${var.project_name}-logs-replica-region-primary-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-logs-replica-region-primary"
  }
}

resource "aws_s3_bucket_versioning" "logs_replica_region_primary" {
  bucket = aws_s3_bucket.logs_replica_region_primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_replica_region_primary" {
  bucket                  = aws_s3_bucket.logs_replica_region_primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_replica_region_primary" {
  bucket = aws_s3_bucket.logs_replica_region_primary.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_replica_region_primary" {
  bucket = aws_s3_bucket.logs_replica_region_primary.id

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

# プライマリリージョンのログバケットのアクセスログ設定
resource "aws_s3_bucket_logging" "logs_replica_region_primary" {
  bucket = aws_s3_bucket.logs_replica_region_primary.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "logs-replica-region-primary-access-logs/"
}

# プライマリリージョンのログバケットのイベント通知
resource "aws_s3_bucket_notification" "logs_replica_region_primary_notification" {
  bucket = aws_s3_bucket.logs_replica_region_primary.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# レプリカリージョンのログバケットのレプリケーション設定
resource "aws_s3_bucket_replication_configuration" "logs_replica_region" {
  provider   = aws.replica
  depends_on = [aws_s3_bucket_versioning.logs_replica_region]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.logs_replica_region.id

  rule {
    id     = "logs-replica-region-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.logs_replica_region_primary.arn
      storage_class = "STANDARD"
    }
  }
}
