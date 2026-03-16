################################################################################
# Auto Scaling Groups
################################################################################

resource "aws_autoscaling_group" "this" {
  for_each = local.asg_instances

  name = "${local.name_prefix}-${each.key}-asg"

  min_size         = each.value.asg_min_size
  max_size         = each.value.asg_max_size
  desired_capacity = each.value.asg_desired_capacity

  vpc_zone_identifier = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : var.subnet_ids

  health_check_type         = each.value.asg_health_check_type
  health_check_grace_period = each.value.asg_health_check_grace_period

  target_group_arns   = each.value.asg_target_group_arns
  suspended_processes = each.value.asg_suspended_processes

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = aws_launch_template.this[each.key].latest_version
  }

  dynamic "instance_refresh" {
    for_each = each.value.asg_instance_refresh ? [1] : []

    content {
      strategy = each.value.asg_instance_refresh_strategy

      preferences {
        min_healthy_percentage = each.value.asg_min_healthy_percentage
      }
    }
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, each.value.tags, {
      Name  = "${local.name_prefix}-${each.key}"
      Group = each.key
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
