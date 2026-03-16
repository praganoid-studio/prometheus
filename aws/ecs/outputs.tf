################################################################################
# Cluster
################################################################################

output "cluster_id" {
  description = "The ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "The ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "The ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

################################################################################
# Services
################################################################################

output "service_arns" {
  description = "Map of service name to service ARN"
  value = {
    for k, v in aws_ecs_service.this : k => v.id
  }
}

output "service_names" {
  description = "Map of service name to ECS service name"
  value = {
    for k, v in aws_ecs_service.this : k => v.name
  }
}

output "task_definition_arns" {
  description = "Map of service name to task definition ARN"
  value = {
    for k, v in aws_ecs_task_definition.this : k => v.arn
  }
}

output "service_security_group_ids" {
  description = "Map of service name to security group ID"
  value = {
    for k, v in aws_security_group.service : k => v.id
  }
}

################################################################################
# IAM
################################################################################

output "task_execution_role_arn" {
  description = "The shared task execution IAM role ARN"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arns" {
  description = "Map of service name to task IAM role ARN"
  value = {
    for k, v in aws_iam_role.task : k => v.arn
  }
}

################################################################################
# Load Balancer
################################################################################

output "alb_arn" {
  description = "ALB ARN (empty if ALB not created)"
  value       = var.enable_alb ? aws_lb.this[0].arn : ""
}

output "alb_dns_name" {
  description = "ALB DNS name (empty if ALB not created)"
  value       = var.enable_alb ? aws_lb.this[0].dns_name : ""
}

output "alb_zone_id" {
  description = "ALB hosted zone ID for Route53 alias records (empty if ALB not created)"
  value       = var.enable_alb ? aws_lb.this[0].zone_id : ""
}

output "alb_security_group_id" {
  description = "ALB security group ID (empty if ALB not created)"
  value       = var.enable_alb ? aws_security_group.alb[0].id : ""
}

output "target_group_arns" {
  description = "Map of service name to target group ARN"
  value = {
    for k, v in aws_lb_target_group.service : k => v.arn
  }
}

output "http_listener_arn" {
  description = "HTTP listener ARN (empty if ALB not created)"
  value       = var.enable_alb ? aws_lb_listener.http[0].arn : ""
}

output "https_listener_arn" {
  description = "HTTPS listener ARN (empty if no certificate or ALB not created)"
  value       = var.enable_alb && var.alb_ssl_certificate_arn != "" ? aws_lb_listener.https[0].arn : ""
}

################################################################################
# Logging
################################################################################

output "log_group_names" {
  description = "Map of service name to CloudWatch log group name"
  value = {
    for k, v in aws_cloudwatch_log_group.service : k => v.name
  }
}

output "log_group_arns" {
  description = "Map of service name to CloudWatch log group ARN"
  value = {
    for k, v in aws_cloudwatch_log_group.service : k => v.arn
  }
}
