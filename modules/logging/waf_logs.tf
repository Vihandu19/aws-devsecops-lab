resource "aws_cloudwatch_log_group" "waf_logs" {
    #checkov:skip=CKV_AWS_338:1-day retention by design for an ephemeral lab; a year of retention would be a standing cost
    #checkov:skip=CKV_AWS_158:Default CloudWatch encryption is used; a customer-managed KMS key is a standing cost avoided in this cost-controlled lab
    name              = "aws-waf-logs-${var.name_prefix}"
    retention_in_days = var.log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
    resource_arn = var.web_acl_arn
    log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
}