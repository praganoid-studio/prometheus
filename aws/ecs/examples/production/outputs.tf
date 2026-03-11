################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

################################################################################
# ECS
################################################################################

output "cluster_name" {
  description = "The ECS cluster name"
  value       = module.ecs.cluster_name
}

output "cluster_arn" {
  description = "The ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "alb_dns_name" {
  description = "The ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "alb_zone_id" {
  description = "The ALB hosted zone ID for Route53"
  value       = module.ecs.alb_zone_id
}

output "service_arns" {
  description = "Map of service ARNs"
  value       = module.ecs.service_arns
}

output "task_execution_role_arn" {
  description = "The shared task execution role ARN"
  value       = module.ecs.task_execution_role_arn
}

output "service_security_group_ids" {
  description = "Map of service security group IDs"
  value       = module.ecs.service_security_group_ids
}
