# AWS EC2 Terraform Module

A production-ready, reusable Terraform module for provisioning AWS EC2 instances using Launch Templates, with support for multiple instance groups, IAM instance profiles, security groups, EBS volumes, Elastic IPs, flexible user data injection, and optional Auto Scaling Groups. Designed for bastion hosts, application servers, worker nodes, CI/CD runners, and other EC2-based workloads.

## Features

- Multiple instance groups via `for_each` — each with its own Launch Template, IAM role, security group, and instance profile
- Launch Templates for versioning, flexibility, and ASG reuse
- Flexible user data — plain strings, `file()`, or `templatefile()` at the call site
- Per-group IAM roles with configurable policy attachments
- SSM Session Manager enabled by default (no SSH keys required for management)
- IMDSv2 enforced by default for enhanced security
- Per-group security groups with configurable ingress rules
- Optional Elastic IPs for standalone instances
- Optional Auto Scaling Groups with instance refresh support
- Configurable root and additional EBS volumes with encryption enabled by default
- Consistent resource tagging strategy

## Usage

```hcl
module "ec2" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/ec2?ref=v1.3.0"

  name_prefix = "my-app"
  environment = "production"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  instances = {
    bastion = {
      ami_id         = "ami-0123456789abcdef0"
      instance_type  = "t3.micro"
      subnet_ids     = module.vpc.public_subnet_ids
      instance_count = 1

      associate_public_ip_address = true
      enable_eip                  = true

      user_data = templatefile("${path.module}/scripts/bastion.sh", {
        environment = "production"
      })

      ingress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["203.0.113.0/32"]
          description = "SSH from office"
        }
      ]
    }

    app = {
      ami_id        = "ami-0123456789abcdef0"
      instance_type = "t3.large"

      root_volume_size = 50
      monitoring       = true

      enable_asg           = true
      asg_min_size         = 2
      asg_max_size         = 10
      asg_desired_capacity = 3
      asg_instance_refresh = true
    }
  }

  tags = {
    Project = "my-app"
  }
}
```

## VPC Integration

This module consumes an existing VPC — it does **not** create any networking resources. Pass in `vpc_id` and `subnet_ids` from any VPC module or data source. Per-group subnet overrides allow placing different groups in different subnets (e.g., bastion in public, workers in private).

```hcl
module "vpc" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/vpc?ref=v1.0.0"

  vpc_name    = "my-app"
  environment = "production"
}

module "ec2" {
  source = "../../"

  name_prefix = "my-app"
  environment = "production"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Name prefix for all resources | `string` | — | yes |
| `environment` | Environment name (dev, staging, production) | `string` | — | yes |
| `vpc_id` | VPC ID for security groups | `string` | — | yes |
| `subnet_ids` | Default subnet IDs for instance placement (minimum 1) | `list(string)` | — | yes |
| `key_name` | Default EC2 Key Pair name (overridable per group) | `string` | `""` | no |
| `instances` | Map of EC2 instance group configurations | `map(object)` | `{}` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_ids` | Map of group name to list of instance IDs |
| `instance_private_ips` | Map of group name to list of private IP addresses |
| `instance_public_ips` | Map of group name to list of public IP addresses |
| `launch_template_ids` | Map of group name to Launch Template ID |
| `launch_template_latest_versions` | Map of group name to latest Launch Template version |
| `instance_profile_arns` | Map of group name to instance profile ARN |
| `iam_role_arns` | Map of group name to IAM role ARN |
| `security_group_ids` | Map of group name to security group ID |
| `eip_public_ips` | Map of group name to list of Elastic IP addresses |
| `asg_arns` | Map of group name to ASG ARN |
| `asg_names` | Map of group name to ASG name |

## Instance Group Configuration

Each entry in `instances` supports:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `ami_id` | `string` | — | AMI ID for the instance |
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type |
| `key_name` | `string` | `""` | Override module-level key pair |
| `subnet_ids` | `list(string)` | `[]` | Override module-level subnet IDs |
| `instance_count` | `number` | `1` | Number of instances (ignored when `enable_asg = true`) |
| `user_data` | `string` | `""` | User data script (plain, `file()`, or `templatefile()`) |
| `user_data_base64` | `string` | `""` | Pre-encoded base64 user data |
| `root_volume_size` | `number` | `20` | Root volume size in GiB |
| `root_volume_type` | `string` | `"gp3"` | Root volume type |
| `root_volume_iops` | `number` | `null` | Root volume provisioned IOPS |
| `root_volume_throughput` | `number` | `null` | Root volume throughput (MiB/s) |
| `root_volume_encrypted` | `bool` | `true` | Encrypt root volume |
| `root_volume_kms_key_id` | `string` | `""` | KMS key ID for root volume encryption |
| `ebs_block_devices` | `list(object)` | `[]` | Additional EBS volumes |
| `associate_public_ip_address` | `bool` | `false` | Associate public IP |
| `enable_eip` | `bool` | `false` | Create Elastic IP (standalone only) |
| `source_dest_check` | `bool` | `true` | Enable source/destination check |
| `iam_policy_arns` | `list(string)` | `[]` | IAM policy ARNs for the instance role |
| `enable_ssm` | `bool` | `true` | Attach SSM managed instance policy |
| `additional_security_group_ids` | `list(string)` | `[]` | Extra security groups |
| `ingress_rules` | `list(object)` | `[]` | Custom ingress rules |
| `metadata_http_tokens` | `string` | `"required"` | IMDSv2 token requirement |
| `metadata_hop_limit` | `number` | `1` | Metadata hop limit |
| `monitoring` | `bool` | `false` | Enable detailed monitoring |
| `enable_asg` | `bool` | `false` | Use ASG instead of standalone instances |
| `asg_min_size` | `number` | `1` | ASG minimum size |
| `asg_max_size` | `number` | `3` | ASG maximum size |
| `asg_desired_capacity` | `number` | `1` | ASG desired capacity |
| `asg_health_check_type` | `string` | `"EC2"` | ASG health check type (EC2 or ELB) |
| `asg_health_check_grace_period` | `number` | `300` | Health check grace period (seconds) |
| `asg_target_group_arns` | `list(string)` | `[]` | Target group ARNs for ALB integration |
| `asg_suspended_processes` | `list(string)` | `[]` | ASG processes to suspend |
| `asg_instance_refresh` | `bool` | `false` | Enable instance refresh on updates |
| `asg_instance_refresh_strategy` | `string` | `"Rolling"` | Instance refresh strategy |
| `asg_min_healthy_percentage` | `number` | `90` | Minimum healthy percentage during refresh |
| `tags` | `map(string)` | `{}` | Additional tags for this group |

## Instance Group Patterns

| Pattern | enable_asg | enable_eip | Example |
|---------|-----------|-----------|---------|
| Bastion host | no | yes | Jump box in public subnet with EIP |
| Application server | no | no | Fixed set of app instances in private subnet |
| Scaled application | yes | no | ASG behind ALB for web traffic |
| Worker fleet | yes | no | ASG for background processing |
| CI/CD runner | yes | no | ASG that scales with build demand |

## User Data

Three approaches are supported at the **call site**:

```hcl
# Plain string
user_data = "#!/bin/bash\nyum update -y"

# File-based
user_data = file("${path.module}/scripts/bootstrap.sh")

# Template-based
user_data = templatefile("${path.module}/scripts/app.sh.tpl", {
  environment = var.environment
  region      = var.aws_region
})
```

## Examples

- [Dev environment](examples/dev/) — Bastion host with EIP + standalone app instances, cost-optimized
- [Production environment](examples/production/) — Bastion host + ASG app servers + ASG worker fleet, detailed monitoring, instance refresh

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS provider | >= 5.0 |
