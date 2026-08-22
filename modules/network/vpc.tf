resource "aws_vpc" "vpc" {
  #checkov:skip=CKV2_AWS_11:Flow logs are configured in the logging module (aws_flow_log.vpc); Checkov cannot trace this across the module boundary
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}