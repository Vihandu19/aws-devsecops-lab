data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "devsecops-lab-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "tfstate" {
  #checkov:skip=CKV2_AWS_62:Event notifications are not needed for the state bucket
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration is not needed; the state bucket is small and long-lived by design
  #checkov:skip=CKV_AWS_18:Access logging is not configured for this single-project lab state bucket
  #checkov:skip=CKV_AWS_144:Cross-region replication is overkill for a personal lab state bucket
  bucket = local.state_bucket_name

  # This bucket holds the state for the whole project. Do not delete
  force_destroy = false

  tags = {
    Name = local.state_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}