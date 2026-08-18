data "aws_region" "current" {}

#S3 gateway endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}


#Systems manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.subnet["private-a"].id,
    aws_subnet.subnet["private-b"].id
  ]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-ssm-endpoint"
  }
}


#Systems manager nessages
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.subnet["private-a"].id,
    aws_subnet.subnet["private-b"].id
  ]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-ssmmessages-endpoint"
  }
}

#EC2 messages
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids = [
    aws_subnet.subnet["private-a"].id,
    aws_subnet.subnet["private-b"].id
  ]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-ec2messages-endpoint"
  }
}