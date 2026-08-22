#Security groups

# Default security group locked 
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

data "aws_prefix_list" "s3" {
  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
}

resource "aws_vpc_security_group_egress_rule" "instance_to_s3" {
  security_group_id = aws_security_group.instance.id
  description       = "HTTPS to S3 via gateway endpoint"
  prefix_list_id    = data.aws_prefix_list.s3.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Attached to the ALB via alb_security_group_id passed to the alb module; Checkov cannot trace attachment across module boundaries
  name_prefix = "${var.name_prefix}-alb-"
  description = "ALB tier: accepts internet traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = { Name = "${var.name_prefix}-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  #checkov:skip=CKV2_AWS_5:Attached to the instances via instance_security_group_id passed to the compute module; Checkov cannot trace attachment across module boundaries
  name_prefix = "${var.name_prefix}-instance-"
  description = "Instance tier: accepts traffic only from ALB"
  vpc_id      = aws_vpc.vpc.id

  tags = { Name = "${var.name_prefix}-instance-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "endpoints" {
  name_prefix = "${var.name_prefix}-endpoints-"
  description = "Interface endpoint tier: accepts HTTPS only from instances"
  vpc_id      = aws_vpc.vpc.id

  tags = { Name = "${var.name_prefix}-endpoints-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

#ALB rules 

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Public ALB must accept HTTP from internet by design
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_instance" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to instances"
  referenced_security_group_id = aws_security_group.instance.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

#Instance rules 

resource "aws_vpc_security_group_ingress_rule" "instance_from_alb" {
  #checkov:skip=CKV_AWS_260:Sources from the ALB security group, not the internet; Checkov flags any port-80 ingress
  security_group_id            = aws_security_group.instance.id
  description                  = "HTTP from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "instance_to_endpoints" {
  security_group_id            = aws_security_group.instance.id
  description                  = "HTTPS to interface endpoints"
  referenced_security_group_id = aws_security_group.endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

#Endpoint rules

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_instance" {
  security_group_id            = aws_security_group.endpoints.id
  description                  = "HTTPS from instances"
  referenced_security_group_id = aws_security_group.instance.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}