locals {
  cluster_name             = var.cluster_name
  control_plane_subnet_ids = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids
  account_id               = data.aws_caller_identity.current.account_id
  partition                = data.aws_partition.current.partition

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eks"
  })
}
