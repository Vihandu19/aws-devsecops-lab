data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "alb_logs"{
    #checkov:skip=CKV2_AWS_62:Event notifications are not needed for an ephemeral access-log bucket
    #checkov:skip=CKV2_AWS_61:Lifecycle configuration is unnecessary; the bucket is destroyed with the stack each session
    #checkov:skip=CKV_AWS_18:Access logging on a log bucket is circular and unnecessary for a lab
    #checkov:skip=CKV_AWS_144:Cross-region replication is overkill for an ephemeral log bucket
    #checkov:skip=CKV_AWS_21:Versioning is unnecessary for ephemeral logs
    #checkov:skip=CKV_AWS_145:SSE-S3 encryption is used by design; a customer-managed KMS key is a standing cost avoided here
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