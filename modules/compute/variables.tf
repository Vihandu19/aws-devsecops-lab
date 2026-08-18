variable "name_prefix" {
  description = "Prefix for resource names and Name tag"
  type        = string
}

variable "private_subnets" {
  description = "Map of private subnet name to ID"
  type        = map(string)
}

variable "instance_security_group_id" {
  description = "ID of the instance-tier security group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.nano"
}