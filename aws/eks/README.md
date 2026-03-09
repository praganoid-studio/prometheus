# AWS EKS Terraform Module

A production-ready, reusable Terraform module for provisioning an AWS EKS cluster with managed node groups, IAM roles, security groups, OIDC provider (IRSA), optional Fargate profiles, and configurable addons. Designed for consumption by ALB, Helm, monitoring, and other infrastructure modules.

## Features

- EKS cluster with configurable Kubernetes version and endpoint access
- Managed node groups with `for_each` — multiple groups with different instance types, sizes, labels, and taints
- Least-privilege IAM roles for cluster, nodes, and Fargate
- Cluster and node security groups with minimal required rules
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Optional Fargate profiles for serverless pod execution
- Managed EKS addons (CoreDNS, kube-proxy, VPC CNI, Pod Identity Agent) with addon ordering
- Optional KMS encryption for Kubernetes secrets
- Configurable control plane logging
- EKS access entries (API mode) for cluster authentication
- Consistent resource tagging strategy

## Usage

```hcl
module "eks" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/eks?ref=v1.0.0"

  cluster_name       = "my-cluster"
  environment        = "production"
  kubernetes_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  eks_managed_node_groups = {
    general = {
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
    }
  }

  tags = {
    Project = "my-app"
  }
}
```

## VPC Integration

This module consumes an existing VPC — it does **not** create any networking resources. Pass in `vpc_id` and `subnet_ids` from any VPC module or data source.

When using with the [VPC module](../vpc/), ensure EKS-required subnet tags are applied:

```hcl
module "vpc" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/vpc?ref=v1.0.0"

  vpc_name    = "eks-cluster"
  environment = "production"

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source = "../../"

  cluster_name = "my-cluster"
  environment  = "production"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name of the EKS cluster | `string` | — | yes |
| `environment` | Environment name (dev, staging, production) | `string` | — | yes |
| `kubernetes_version` | Kubernetes version | `string` | `"1.31"` | no |
| `vpc_id` | VPC ID for the cluster | `string` | — | yes |
| `subnet_ids` | Private subnet IDs (minimum 2) | `list(string)` | — | yes |
| `control_plane_subnet_ids` | Optional separate subnets for control plane ENIs | `list(string)` | `[]` | no |
| `endpoint_public_access` | Enable public API endpoint | `bool` | `true` | no |
| `endpoint_private_access` | Enable private API endpoint | `bool` | `true` | no |
| `public_access_cidrs` | CIDRs allowed to access public endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| `enabled_cluster_log_types` | Control plane log types to enable | `list(string)` | `[]` | no |
| `cluster_encryption_kms_key_arn` | KMS key ARN for secrets encryption | `string` | `""` | no |
| `eks_managed_node_groups` | Map of managed node group configurations | `map(object)` | `{}` | no |
| `fargate_profiles` | Map of Fargate profile configurations | `map(object)` | `{}` | no |
| `cluster_addons` | Map of EKS addon configurations | `map(object)` | CoreDNS, kube-proxy, VPC CNI, Pod Identity | no |
| `enable_cluster_creator_admin_permissions` | Grant Terraform caller admin access | `bool` | `true` | no |
| `access_entries` | Additional IAM principal access entries | `map(object)` | `{}` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | The EKS cluster name |
| `cluster_arn` | The EKS cluster ARN |
| `cluster_endpoint` | API server endpoint URL |
| `cluster_certificate_authority_data` | Base64-encoded CA cert |
| `cluster_version` | Kubernetes version |
| `cluster_platform_version` | EKS platform version |
| `cluster_primary_security_group_id` | EKS-managed primary security group ID |
| `cluster_security_group_id` | Cluster security group ID (this module) |
| `node_security_group_id` | Node security group ID (this module) |
| `cluster_iam_role_arn` | Cluster IAM role ARN |
| `node_group_iam_role_arn` | Node group IAM role ARN |
| `fargate_pod_execution_role_arn` | Fargate execution role ARN |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `oidc_provider_url` | OIDC provider URL |
| `eks_managed_node_groups` | Map of node group attributes |
| `fargate_profiles` | Map of Fargate profile attributes |

## Node Group Configuration

Each entry in `eks_managed_node_groups` supports:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `ami_type` | `string` | `"AL2023_x86_64_STANDARD"` | AMI type for nodes |
| `instance_types` | `list(string)` | `["m5.large"]` | EC2 instance types |
| `capacity_type` | `string` | `"ON_DEMAND"` | ON_DEMAND or SPOT |
| `disk_size` | `number` | `50` | EBS volume size (GiB) |
| `min_size` | `number` | `1` | Minimum node count |
| `max_size` | `number` | `3` | Maximum node count |
| `desired_size` | `number` | `2` | Desired node count |
| `labels` | `map(string)` | `{}` | Kubernetes labels |
| `taints` | `list(object)` | `[]` | Kubernetes taints |
| `tags` | `map(string)` | `{}` | Additional tags |

## Examples

- [Dev environment](examples/dev/) — Single SPOT node group, public endpoint, cost-optimized
- [Production environment](examples/production/) — Multiple ON_DEMAND node groups, restricted endpoint, logging, encryption

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS provider | >= 5.0 |
| TLS provider | >= 4.0 |
