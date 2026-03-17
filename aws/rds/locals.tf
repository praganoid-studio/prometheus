locals {
  name_prefix = var.name_prefix
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.id

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "rds"
  })

  is_aurora = var.cluster_mode != null ? var.cluster_mode : contains(
    ["aurora-postgresql", "aurora-mysql"], var.engine
  )

  port = coalesce(var.port, (
    contains(["postgres", "aurora-postgresql"], var.engine) ? 5432 : 3306
  ))

  final_snapshot_identifier = coalesce(
    var.final_snapshot_identifier,
    "${var.name_prefix}-final-snapshot"
  )

  enhanced_monitoring_enabled = var.monitoring_interval > 0
}
