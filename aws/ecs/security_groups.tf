################################################################################
# ALB Security Group
################################################################################

resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${local.cluster_name}-alb-sg"
  description = "Security group for ECS ALB"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  count = var.enable_alb ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTP inbound"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  count = var.enable_alb && var.alb_ssl_certificate_arn != "" ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS inbound"
}

resource "aws_security_group_rule" "alb_egress" {
  count = var.enable_alb ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all outbound traffic"
}

################################################################################
# Per-Service Security Groups
################################################################################

resource "aws_security_group" "service" {
  for_each = var.services

  name        = "${local.cluster_name}-${each.key}-sg"
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, each.value.tags, {
    Name    = "${local.cluster_name}-${each.key}-sg"
    Service = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "service_egress" {
  for_each = var.services

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.service[each.key].id
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "service_ingress_alb" {
  for_each = local.lb_services

  type                     = "ingress"
  from_port                = each.value.container_port
  to_port                  = each.value.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  security_group_id        = aws_security_group.service[each.key].id
  description              = "Allow inbound from ALB on container port"
}

resource "aws_security_group_rule" "service_ingress_custom" {
  for_each = {
    for pair in flatten([
      for svc_key, svc in var.services : [
        for idx, rule in svc.ingress_rules : {
          key                      = "${svc_key}-${idx}"
          svc_key                  = svc_key
          from_port                = rule.from_port
          to_port                  = rule.to_port
          protocol                 = rule.protocol
          cidr_blocks              = rule.cidr_blocks
          source_security_group_id = rule.source_security_group_id
          description              = rule.description
        }
      ]
    ]) : pair.key => pair
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.service[each.value.svc_key].id
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id != "" ? each.value.source_security_group_id : null
}
