################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "this" {
  count = var.enable_alb ? 1 : 0

  name               = "${local.cluster_name}-alb"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.public_subnet_ids
  idle_timeout       = var.alb_idle_timeout

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-alb"
  })
}

################################################################################
# Target Groups
################################################################################

resource "aws_lb_target_group" "service" {
  for_each = local.lb_services

  name        = "${local.cluster_name}-${each.key}"
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = each.value.health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${local.cluster_name}-${each.key}"
    Service = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# HTTP Listener
################################################################################

resource "aws_lb_listener" "http" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.alb_ssl_certificate_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.alb_ssl_certificate_arn == "" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body = "No route matched"
        status_code  = "404"
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-http"
  })
}

################################################################################
# HTTPS Listener
################################################################################

resource "aws_lb_listener" "https" {
  count = var.enable_alb && var.alb_ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = var.alb_ssl_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No route matched"
      status_code  = "404"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-https"
  })
}

################################################################################
# Listener Rules
################################################################################

resource "aws_lb_listener_rule" "service_https" {
  for_each = var.alb_ssl_certificate_arn != "" ? local.lb_services : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = each.value.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name    = "${local.cluster_name}-${each.key}-https-rule"
    Service = each.key
  })
}

resource "aws_lb_listener_rule" "service_http" {
  for_each = var.alb_ssl_certificate_arn == "" ? local.lb_services : {}

  listener_arn = aws_lb_listener.http[0].arn
  priority     = each.value.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = merge(local.common_tags, {
    Name    = "${local.cluster_name}-${each.key}-http-rule"
    Service = each.key
  })
}
