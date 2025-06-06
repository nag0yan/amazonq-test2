provider "aws" {
  region = var.aws_region
}

# ランダム文字列生成（バケット名のユニーク化）
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# データソース
data "aws_elb_service_account" "main" {}
data "aws_caller_identity" "current" {}
