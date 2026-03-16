################################################################################
# Task Definitions
################################################################################

resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${local.cluster_name}-${each.key}"
  requires_compatibilities = [each.value.launch_type]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task[each.key].arn
  container_definitions    = each.value.container_definitions

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${local.cluster_name}-${each.key}"
    Service = each.key
  })
}

################################################################################
# ECS Services
################################################################################

resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type

  platform_version       = each.value.launch_type == "FARGATE" ? each.value.platform_version : null
  force_new_deployment   = each.value.force_new_deployment
  enable_execute_command = each.value.enable_execute_command

  deployment_minimum_healthy_percent = each.value.deployment_min_percent
  deployment_maximum_percent         = each.value.deployment_max_percent

  health_check_grace_period_seconds = each.value.enable_load_balancer ? each.value.health_check_grace_period : null

  network_configuration {
    subnets = length(each.value.service_subnet_ids) > 0 ? each.value.service_subnet_ids : var.private_subnet_ids
    security_groups = concat(
      [aws_security_group.service[each.key].id],
      each.value.additional_security_group_ids
    )
    assign_public_ip = each.value.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.value.enable_load_balancer && var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.service[each.key].arn
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  propagate_tags = "TASK_DEFINITION"

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${local.cluster_name}-${each.key}"
    Service = each.key
  })

  depends_on = [
    aws_iam_role_policy_attachment.task_execution,
    aws_lb_listener.http,
    aws_lb_listener.https,
  ]
}
