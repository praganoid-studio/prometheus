################################################################################
# Enhanced Monitoring IAM Role
################################################################################

resource "aws_iam_role" "enhanced_monitoring" {
  count = local.enhanced_monitoring_enabled ? 1 : 0

  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-monitoring-role"
  })
}

################################################################################
# Enhanced Monitoring Policy Attachment
################################################################################

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = local.enhanced_monitoring_enabled ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
