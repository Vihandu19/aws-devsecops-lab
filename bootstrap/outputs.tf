output "state_bucket" {
  description = "Name of the state bucket, used in the backend block of environments/lab"
  value       = aws_s3_bucket.tfstate.id
}

output "plan_role_arn" {
  description = "ARN of the GitHub Actions plan role"
  value       = aws_iam_role.gha_plan.arn
}

output "apply_role_arn" {
  description = "ARN of the GitHub Actions apply role"
  value       = aws_iam_role.gha_apply.arn
}