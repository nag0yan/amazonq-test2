# ALB用のWAF Web ACL
resource "aws_wafv2_web_acl" "alb" {
  name        = "${var.project_name}-alb-web-acl"
  description = "WAF Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS管理ルール - コアルールセット
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS管理ルール - Log4j対策
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS管理ルール - Log4j AMR対策
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  # カスタムルール - Log4j JNDI対策
  rule {
    name     = "CustomLog4jProtection"
    priority = 4

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.log4j_patterns.arn
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CustomLog4jProtection"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-alb-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-alb-web-acl"
  }
}

# Log4j脆弱性対策のための正規表現パターンセット
resource "aws_wafv2_regex_pattern_set" "log4j_patterns" {
  name        = "${var.project_name}-log4j-patterns"
  description = "Regex patterns to detect Log4j JNDI exploitation attempts"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "(?i)\\$\\{jndi:(?:ldap[s]?|rmi|dns|nis|iiop|corba|nds|http)://"
  }

  tags = {
    Name = "${var.project_name}-log4j-patterns"
  }
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-web-acl"
  description = "WAF Web ACL for ${var.project_name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS管理ルール - コアルールセット
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS管理ルール - SQLインジェクション対策
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS管理ルール - Log4j対策
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS管理ルール - Log4j AMR対策
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  # カスタムルール - Log4j JNDI対策
  rule {
    name     = "CustomLog4jProtection"
    priority = 5

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.log4j_patterns_cloudfront.arn
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CustomLog4jProtection"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-web-acl"
  }
}

# Log4j脆弱性対策のための正規表現パターンセット (CloudFront用)
resource "aws_wafv2_regex_pattern_set" "log4j_patterns_cloudfront" {
  name        = "${var.project_name}-log4j-patterns-cloudfront"
  description = "Regex patterns to detect Log4j JNDI exploitation attempts"
  scope       = "CLOUDFRONT"

  regular_expression {
    regex_string = "(?i)\\$\\{jndi:(?:ldap[s]?|rmi|dns|nis|iiop|corba|nds|http)://"
  }

  tags = {
    Name = "${var.project_name}-log4j-patterns-cloudfront"
  }
}

# WAF logging configuration for CloudFront WAF
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# WAF logging configuration for ALB WAF
resource "aws_wafv2_web_acl_logging_configuration" "alb" {
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.alb.arn
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
