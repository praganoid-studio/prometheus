locals {
  cluster_name = var.cluster_name
  account_id   = data.aws_caller_identity.current.account_id
  partition    = data.aws_partition.current.partition
  region       = data.aws_region.current.id

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ecs"
  })

  lb_services = {
    for k, v in var.services : k => v if v.enable_load_balancer && var.enable_alb
  }

  autoscaled_services = {
    for k, v in var.services : k => v if v.enable_autoscaling
  }
}
