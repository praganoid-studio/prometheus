################################################################################
# Per-Service CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/ecs/${local.cluster_name}/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "/ecs/${local.cluster_name}/${each.key}"
    Service = each.key
  })
}
