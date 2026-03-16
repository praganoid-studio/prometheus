################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

################################################################################
# EC2
################################################################################

output "instance_ids" {
  description = "Map of group name to list of instance IDs"
  value       = module.ec2.instance_ids
}

output "instance_private_ips" {
  description = "Map of group name to list of private IP addresses"
  value       = module.ec2.instance_private_ips
}

output "instance_public_ips" {
  description = "Map of group name to list of public IP addresses"
  value       = module.ec2.instance_public_ips
}

output "eip_public_ips" {
  description = "Map of group name to list of Elastic IP addresses"
  value       = module.ec2.eip_public_ips
}

output "security_group_ids" {
  description = "Map of group name to security group ID"
  value       = module.ec2.security_group_ids
}

output "launch_template_ids" {
  description = "Map of group name to Launch Template ID"
  value       = module.ec2.launch_template_ids
}
