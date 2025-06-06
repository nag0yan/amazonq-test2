variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "webapp"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c1638aa346a43fe8" # Amazon Linux 2023 AMI (adjust as needed)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  description = "Desired capacity for Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "Minimum size for Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size for Auto Scaling Group"
  type        = number
  default     = 4
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "webappdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  default     = "changeme" # 本番環境では必ず変更してください
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com" # 実際のドメイン名に変更してください
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
  default     = "" # 実際のACM証明書ARNに変更してください
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access to ALB"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # 内部ネットワークのみ許可
}

variable "replica_region" {
  description = "AWS region for S3 bucket replication"
  type        = string
  default     = "us-west-2" # Primary region is ap-northeast-1, so using a different region for DR
}

# ElastiCache変数
variable "cache_node_type" {
  description = "ElastiCacheのノードタイプ"
  type        = string
  default     = "cache.t3.micro"
}

variable "cache_clusters" {
  description = "ElastiCacheのクラスター数"
  type        = number
  default     = 2
}

variable "cache_auth_token" {
  description = "ElastiCacheの認証トークン"
  type        = string
  sensitive   = true
  default     = null
}
