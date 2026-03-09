# AWS VPC Terraform Module

A production-ready, reusable Terraform module for provisioning an AWS VPC with public and private subnets, NAT gateways, internet gateway, and route tables. Designed for consumption by ECS, EKS, RDS, ALB, and other infrastructure modules.

## Features

- VPC with configurable CIDR block, DNS support, and optional IPv6
- Public and private subnets spread across multiple availability zones
- Internet gateway for public subnet internet access
- NAT gateways for private subnet egress (single or per-AZ for HA)
- Dynamic subnet CIDR calculation via `cidrsubnet()` — no hardcoded CIDRs
- Auto-detected availability zones with optional override
- Consistent resource tagging with support for custom and per-subnet tags
- EKS-compatible subnet tagging via `public_subnet_tags` / `private_subnet_tags`

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/vpc?ref=v1.0.0"

  vpc_name       = "my-app"
  environment    = "production"
  vpc_cidr_block = "10.2.0.0/16"

  public_subnet_count  = 3
  private_subnet_count = 3
  single_nat_gateway   = false

  tags = {
    Project = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_name` | Name prefix for all resources | `string` | — | yes |
| `environment` | Environment name (dev, staging, production) | `string` | — | yes |
| `vpc_cidr_block` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `azs` | List of availability zones (auto-detected if empty) | `list(string)` | `[]` | no |
| `public_subnet_count` | Number of public subnets | `number` | `3` | no |
| `private_subnet_count` | Number of private subnets | `number` | `3` | no |
| `public_subnet_newbits` | Newbits for `cidrsubnet()` for public subnets | `number` | `8` | no |
| `private_subnet_newbits` | Newbits for `cidrsubnet()` for private subnets | `number` | `8` | no |
| `public_subnet_offset` | Starting netnum offset for public subnets | `number` | `0` | no |
| `private_subnet_offset` | Starting netnum offset for private subnets | `number` | `10` | no |
| `enable_nat_gateway` | Create NAT gateways for private subnets | `bool` | `true` | no |
| `single_nat_gateway` | Use one shared NAT gateway (cost saving) | `bool` | `false` | no |
| `enable_dns_support` | Enable DNS support in VPC | `bool` | `true` | no |
| `enable_dns_hostnames` | Enable DNS hostnames in VPC | `bool` | `true` | no |
| `enable_ipv6` | Assign IPv6 CIDR block to VPC | `bool` | `false` | no |
| `map_public_ip_on_launch` | Auto-assign public IPs in public subnets | `bool` | `true` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |
| `public_subnet_tags` | Additional tags for public subnets only | `map(string)` | `{}` | no |
| `private_subnet_tags` | Additional tags for private subnets only | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `vpc_cidr_block` | The CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `public_subnet_cidr_blocks` | List of public subnet CIDR blocks |
| `private_subnet_cidr_blocks` | List of private subnet CIDR blocks |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | List of private route table IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_gateway_public_ips` | Elastic IPs of the NAT Gateways |
| `internet_gateway_id` | ID of the Internet Gateway |
| `azs` | Availability zones used |

## CIDR Strategy

The module uses `cidrsubnet()` to carve subnets from the VPC CIDR:

| Subnet Type | Default Newbits | Default Offset | Example (10.0.0.0/16) |
|-------------|-----------------|----------------|-----------------------|
| Public | 8 | 0 | 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24 |
| Private | 8 | 10 | 10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24 |

For larger subnets (e.g. EKS workloads), set `newbits = 4` to get `/20` subnets with 4,096 IPs each.

Recommended non-overlapping CIDRs for multi-environment setups:

- dev: `10.0.0.0/16`
- staging: `10.1.0.0/16`
- production: `10.2.0.0/16`

## EKS Integration

To use this VPC with EKS, pass the required subnet tags:

```hcl
module "vpc" {
  source = "../../"

  vpc_name    = "eks-cluster"
  environment = "production"

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

## Examples

- [Dev environment](examples/dev/) — 2 AZs, single NAT gateway
- [Production environment](examples/production/) — 3 AZs, per-AZ NAT gateways, EKS tags

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS provider | >= 5.0 |
