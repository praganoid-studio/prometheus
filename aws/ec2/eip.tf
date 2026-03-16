################################################################################
# Elastic IPs
################################################################################

resource "aws_eip" "this" {
  for_each = local.eip_instances

  domain = "vpc"

  tags = merge(local.common_tags, var.instances[each.value.group_key].tags, {
    Name  = "${local.name_prefix}-${each.value.group_key}-eip-${each.value.index}"
    Group = each.value.group_key
  })
}

################################################################################
# Elastic IP Associations
################################################################################

resource "aws_eip_association" "this" {
  for_each = local.eip_instances

  allocation_id = aws_eip.this[each.key].id
  instance_id   = aws_instance.this[each.key].id
}
