variable "name_prefix" {
  description = "Prefix for resource names and the Name tag"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name_prefix))
    error_message = "Lowercase alphanumeric and hyphens, starting with a letter, max 21 chars."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "subnets" {
  description = "Subnet configuration keyed by name"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    type              = string
  }))

  validation {
    condition = alltrue([
      for s in values(var.subnets) : contains(["public", "private"], s.type)
    ])
    error_message = "Each subnet type must be public or private."
  }
}