resource "aws_cloudwatch_log_group" "flow_logs" {
    name              = "/aws/vpc/${var.name_prefix}-flow-logs"
    retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "flow_logs" {
    name = "${var.name_prefix}-flow-logs-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "vpc-flow-logs.amazonaws.com"
                }
            }
        ]
    })
}


resource "aws_iam_role_policy" "flow_logs" {
    name = "flow-logs-to-cloudwatch"
    role = aws_iam_role.flow_logs.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ]
                Effect   = "Allow"
                Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
            }
        ]
    })
}

resource "aws_flow_log" "vpc" {
    vpc_id = var.vpc_id
    traffic_type = "ALL"
    log_destination = aws_cloudwatch_log_group.flow_logs.arn
    iam_role_arn = aws_iam_role.flow_logs.arn
}