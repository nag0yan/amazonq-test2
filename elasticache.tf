# ElastiCache Redis クラスター
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-cache-subnet-group"
  }
}

resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-cache-params"
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.project_name}-cache-params"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "Redis cache for ${var.project_name}"
  node_type                  = var.cache_node_type
  num_cache_clusters         = var.cache_clusters
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.cache.id]
  port                       = 6379
  automatic_failover_enabled = var.cache_clusters > 1 ? true : false
  multi_az_enabled           = var.cache_clusters > 1 ? true : false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = aws_kms_key.elasticache.arn
  auth_token                 = var.cache_auth_token

  tags = {
    Name = "${var.project_name}-redis"
  }
}

# ElastiCache用のKMSキー
resource "aws_kms_key" "elasticache" {
  description             = "KMS key for ElastiCache encryption"
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
          Service = "elasticache.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-elasticache-kms-key"
  }
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${var.project_name}-elasticache-kms-key"
  target_key_id = aws_kms_key.elasticache.key_id
}

# ElastiCache用のセキュリティグループ
resource "aws_security_group" "cache" {
  name        = "${var.project_name}-cache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Redis from EC2 instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name = "${var.project_name}-cache-sg"
  }
}

# EC2からElastiCacheへのアクセス許可
resource "aws_security_group_rule" "ec2_to_cache" {
  security_group_id        = aws_security_group.ec2.id
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cache.id
  description              = "Allow Redis to ElastiCache"
}
