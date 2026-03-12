################################################################################
# Per-Group Security Groups
################################################################################

resource "aws_security_group" "this" {
  for_each = var.instances

  name        = "${local.name_prefix}-${each.key}-sg"
  description = "Security group for EC2 instance group ${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, each.value.tags, {
    Name  = "${local.name_prefix}-${each.key}-sg"
    Group = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Egress Rules
################################################################################

resource "aws_security_group_rule" "egress" {
  for_each = var.instances

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this[each.key].id
  description       = "Allow all outbound traffic"
}

################################################################################
# Custom Ingress Rules
################################################################################

resource "aws_security_group_rule" "ingress_custom" {
  for_each = {
    for pair in flatten([
      for group_key, group in var.instances : [
        for idx, rule in group.ingress_rules : {
          key                      = "${group_key}-${idx}"
          group_key                = group_key
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
  security_group_id = aws_security_group.this[each.value.group_key].id
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id != "" ? each.value.source_security_group_id : null
}
