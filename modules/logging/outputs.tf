output "alb_log_bucket" {
  description = "Name of the ALB access-log bucket; feeds the ALB module"
  value       = aws_s3_bucket.alb_logs.id
}