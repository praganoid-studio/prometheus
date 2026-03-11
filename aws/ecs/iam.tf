################################################################################
# Shared Task Execution Role
################################################################################

resource "aws_iam_role" "task_execution" {
  name = "${local.cluster_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
# Per-Service Task Roles
################################################################################

resource "aws_iam_role" "task" {
  for_each = var.services

  name = "${local.cluster_name}-${each.key}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${local.cluster_name}-${each.key}-task-role"
    Service = each.key
  })
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = {
    for pair in flatten([
      for svc_key, svc in var.services : [
        for idx, arn in svc.task_role_policy_arns : {
          key        = "${svc_key}-${idx}"
          role_name  = aws_iam_role.task[svc_key].name
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = each.value.role_name
  policy_arn = each.value.policy_arn
}
