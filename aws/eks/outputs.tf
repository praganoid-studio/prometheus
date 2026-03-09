################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "The Kubernetes version running on the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The EKS platform version of the cluster"
  value       = aws_eks_cluster.this.platform_version
}

################################################################################
# Security
################################################################################

output "cluster_primary_security_group_id" {
  description = "The EKS-managed primary security group ID (auto-created by AWS)"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_id" {
  description = "The additional cluster security group ID created by this module"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "The node security group ID created by this module"
  value       = aws_security_group.node.id
}

################################################################################
# IAM
################################################################################

output "cluster_iam_role_arn" {
  description = "The IAM role ARN used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "The IAM role ARN used by managed node groups"
  value       = length(aws_iam_role.node) > 0 ? aws_iam_role.node[0].arn : ""
}

output "fargate_pod_execution_role_arn" {
  description = "The Fargate pod execution IAM role ARN"
  value       = length(aws_iam_role.fargate) > 0 ? aws_iam_role.fargate[0].arn : ""
}

################################################################################
# OIDC (for IRSA)
################################################################################

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider (without https:// prefix)"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

################################################################################
# Compute
################################################################################

output "eks_managed_node_groups" {
  description = "Map of managed node group attributes"
  value = {
    for k, v in aws_eks_node_group.this : k => {
      arn    = v.arn
      status = v.status
    }
  }
}

output "fargate_profiles" {
  description = "Map of Fargate profile attributes"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => {
      arn    = v.arn
      status = v.status
    }
  }
}
