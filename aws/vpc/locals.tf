locals {
  azs = length(var.azs) > 0 ? var.azs : slice(
    data.aws_availability_zones.available.names,
    0,
    max(var.public_subnet_count, var.private_subnet_count)
  )

  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.private_subnet_count) : 0

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "vpc"
  })
}
