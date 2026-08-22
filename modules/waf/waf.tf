resource "aws_wafv2_web_acl" "waf" {
    #checkov:skip=CKV2_AWS_31:Logging is configured by aws_wafv2_web_acl_logging_configuration in the logging module; Checkov cannot trace it across the module boundary
    name        = "${var.name_prefix}-web-acl"
    description = "Regional web ACL for the ALB"
    scope       = "REGIONAL"

    default_action {
        allow {}
    }

    #AWS core ruleset for WAFv2
    rule {
        name    = "AWSCommonRules"
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
            metric_name                = "${var.name_prefix}-common-rules"
            sampled_requests_enabled   = true
        }
    }


    #known bad inputs 
    rule {
        name    = "AWSKnownBadInputs"
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
            metric_name                = "${var.name_prefix}-known-bad-inputs"
            sampled_requests_enabled   = true
        }
    }


    #Rate limiting rule
    rule {
        name     = "RateLimit"
        priority = 3

        action {
            block {}
        }

        statement {
            rate_based_statement {
                limit = var.rate_limit
                aggregate_key_type = "IP"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "${var.name_prefix}-rate-limit"
            sampled_requests_enabled   = true
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-web-acl"
        sampled_requests_enabled   = true
        }

    tags = {
        Name = "${var.name_prefix}-web-acl"
    }
}

resource "aws_wafv2_web_acl_association" "waf_association" {
    resource_arn = var.alb_arn
    web_acl_arn  = aws_wafv2_web_acl.waf.arn
}
