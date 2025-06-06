# セキュリティグループ - ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP接続はHTTPSにリダイレクトするため許可
  # 特定のIPアドレス範囲からのみHTTPアクセスを許可
  ingress {
    description = "Allow HTTP from specific IP ranges for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks # 変数で許可するIPアドレス範囲を指定
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# セキュリティグループ - EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow HTTPS for external services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# セキュリティグループ - RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL from EC2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ALBセキュリティグループのEgressルール（循環参照を避けるため分離）
resource "aws_security_group_rule" "alb_to_ec2" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  description              = "Allow outbound traffic to EC2 instances"
}

# EC2セキュリティグループのEgressルール（循環参照を避けるため分離）
resource "aws_security_group_rule" "ec2_to_rds" {
  security_group_id        = aws_security_group.ec2.id
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow MySQL to RDS"
}
