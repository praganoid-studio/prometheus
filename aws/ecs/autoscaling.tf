################################################################################
# Auto Scaling Targets
################################################################################

resource "aws_appautoscaling_target" "service" {
  for_each = local.autoscaled_services

  max_capacity       = each.value.autoscaling_max_capacity
  min_capacity       = each.value.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

################################################################################
# CPU Target Tracking
################################################################################

resource "aws_appautoscaling_policy" "cpu" {
  for_each = local.autoscaled_services

  name               = "${local.cluster_name}-${each.key}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = each.value.autoscaling_cpu_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

################################################################################
# Memory Target Tracking
################################################################################

resource "aws_appautoscaling_policy" "memory" {
  for_each = local.autoscaled_services

  name               = "${local.cluster_name}-${each.key}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = each.value.autoscaling_memory_target

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
