output "instance_ids" {
  description = "Map of subnet name to instance ID"
  value       = { for k, i in aws_instance.ec2 : k => i.id }
}

output "instance_private_ips" {
  description = "Map of subnet name to private IP"
  value       = { for k, i in aws_instance.ec2 : k => i.private_ip }
}