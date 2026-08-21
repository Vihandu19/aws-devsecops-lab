data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "alb_logs"{
    bucket = "${var.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}"
    force_destroy = true

    tags = {
        Name = "${var.name_prefix}-alb-logs"
    }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
    bucket = aws_s3_bucket.alb_logs.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
    bucket = aws_s3_bucket.alb_logs.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "AllowALBLogDelivery"
                Effect = "Allow"
                Principal = {
                    Service = "logdelivery.elasticloadbalancing.amazonaws.com"
                }
                Action = "s3:PutObject"
                Resource = "${aws_s3_bucket.alb_logs.arn}/*"

            }
        ]
    })
}