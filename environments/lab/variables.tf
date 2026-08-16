variable "project" {
  description = "Project tag; teardown verification greps on this"
  type        = string
  default     = "devsecops-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "owner" {
  description = "Owner tag; set in terraform.tfvars"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}