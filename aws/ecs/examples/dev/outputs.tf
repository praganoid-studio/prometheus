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

output "service_arns" {
  description = "Map of service ARNs"
  value       = module.ecs.service_arns
}
