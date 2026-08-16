#VPC outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}


#Subnet outputs 

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = [
    for key, subnet in aws_subnet.subnet :
    subnet.id
    if var.subnets[key].type == "public"
  ]
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value = [
    for key, subnet in aws_subnet.subnet :
    subnet.id
    if var.subnets[key].type == "private"
  ]
}

#Endpoint outputs
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}