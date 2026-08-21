variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC to attach flow logs to"
  type        = string
}

variable "web_acl_arn" {
  description = "ARN of the WAF Web ACL to log"
  type        = string
}

variable "log_retention_days" {
  description = "Retention for CloudWatch log groups"
  type        = number
  default     = 1
}