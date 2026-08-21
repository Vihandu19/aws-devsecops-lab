resource "aws_cloudwatch_log_group" "waf_logs" {
    name              = "aws-waf-logs-${var.name_prefix}"
    retention_in_days = var.log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
    resource_arn = var.web_acl_arn
    log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
}