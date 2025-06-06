# S3 bucket event notifications
resource "aws_s3_bucket_notification" "flow_logs_notification" {
  bucket = aws_s3_bucket.flow_logs.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

resource "aws_s3_bucket_notification" "logs_notification" {
  bucket = aws_s3_bucket.logs.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

resource "aws_s3_bucket_notification" "static_notification" {
  bucket = aws_s3_bucket.static.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_notification" "waf_logs_notification" {
  bucket = aws_s3_bucket.waf_logs.id

  topic {
    topic_arn     = aws_sns_topic.s3_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# SNS Topic for S3 notifications
resource "aws_sns_topic" "s3_notifications" {
  name              = "${var.project_name}-s3-notifications"
  kms_master_key_id = aws_kms_key.sns.arn
}
