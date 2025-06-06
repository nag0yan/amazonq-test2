# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  allocated_storage                   = 20
  storage_type                        = "gp2"
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = var.db_instance_class
  identifier                          = "${var.project_name}-db"
  db_name                             = var.db_name
  username                            = var.db_username
  password                            = var.db_password
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = aws_db_subnet_group.main.name
  vpc_security_group_ids              = [aws_security_group.rds.id]
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${var.project_name}-db-final-snapshot"
  multi_az                            = var.db_multi_az
  storage_encrypted                   = true
  auto_minor_version_upgrade          = true
  deletion_protection                 = true
  copy_tags_to_snapshot               = true
  backup_retention_period             = 7
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  iam_database_authentication_enabled = true
  monitoring_interval                 = 60 # Enable enhanced monitoring (60 second intervals)
  monitoring_role_arn                 = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name = "${var.project_name}-db"
  }
}
