variable "name_prefix" {
  description = "Prefix for resource names and Name tag"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the target group lives in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB spans"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB-tier security group"
  type        = string
}

variable "instance_ids" {
  description = "Map of instance name to ID for target group attachment"
  type        = map(string)
}

variable "enable_access_logs" {
  description = "Enable ALB access logging (wired in the deferred logging phase)"
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "S3 bucket for ALB access logs; only used when enable_access_logs is true"
  type        = string
  default     = ""
}