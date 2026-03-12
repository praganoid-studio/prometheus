################################################################################
# Per-Group IAM Roles
################################################################################

resource "aws_iam_role" "this" {
  for_each = var.instances

  name = "${local.name_prefix}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, each.value.tags, {
    Name  = "${local.name_prefix}-${each.key}-role"
    Group = each.key
  })
}

################################################################################
# Per-Group Instance Profiles
################################################################################

resource "aws_iam_instance_profile" "this" {
  for_each = var.instances

  name = "${local.name_prefix}-${each.key}-profile"
  role = aws_iam_role.this[each.key].name

  tags = merge(local.common_tags, each.value.tags, {
    Name  = "${local.name_prefix}-${each.key}-profile"
    Group = each.key
  })
}

################################################################################
# Custom IAM Policy Attachments
################################################################################

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = local.iam_policy_attachments

  role       = aws_iam_role.this[each.value.group_key].name
  policy_arn = each.value.policy_arn
}

################################################################################
# SSM Policy Attachment (conditional)
################################################################################

resource "aws_iam_role_policy_attachment" "ssm" {
  for_each = local.ssm_groups

  role       = aws_iam_role.this[each.key].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
