################################################################################
# EKS Addons
################################################################################

resource "aws_eks_addon" "before_compute" {
  for_each = { for k, v in var.cluster_addons : k => v if v.before_compute }

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-addon-${each.key}"
  })
}

resource "aws_eks_addon" "after_compute" {
  for_each = { for k, v in var.cluster_addons : k => v if !v.before_compute }

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-addon-${each.key}"
  })

  depends_on = [aws_eks_node_group.this]
}
