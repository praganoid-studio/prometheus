# AWS RDS Terraform Module

A production-ready, reusable Terraform module for provisioning AWS RDS databases, supporting both standard RDS instances (PostgreSQL, MySQL, MariaDB) and Aurora clusters (Aurora PostgreSQL, Aurora MySQL). The module automatically determines the resource type from the engine, creates DB subnet groups, security groups, parameter groups, option groups, and optional Enhanced Monitoring IAM roles. Designed for application databases, microservices, analytics, and multi-environment deployments.

## Features

- **Dual mode** — standard RDS instances and Aurora clusters via a single interface, auto-detected from the `engine` variable
- DB subnet groups using private subnets from an existing VPC module
- Per-database security groups with configurable ingress from security groups and CIDR blocks
- DB parameter groups and cluster parameter groups with customizable parameters
- Option groups for standard RDS engines
- Secrets Manager-managed master passwords (`manage_master_user_password`)
- Storage encryption enabled by default
- Performance Insights and Enhanced Monitoring support with automatic IAM role provisioning
- CloudWatch log exports for engine-specific log types
- Storage autoscaling via `max_allocated_storage` (standard RDS)
- Multi-AZ for standard RDS; multi-instance replicas for Aurora
- Configurable backup retention, maintenance windows, and deletion protection
- Consistent resource tagging strategy

## Usage

### Standard RDS Instance (PostgreSQL)

```hcl
module "rds" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/rds?ref=v1.2.0"

  name_prefix        = "my-app"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"

  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true

  multi_az            = true
  deletion_protection = true

  backup_retention_period = 14

  performance_insights_enabled = true
  monitoring_interval          = 60

  allowed_security_group_ids = [module.ec2.security_group_ids["app"]]

  tags = {
    Project = "my-app"
  }
}
```

### Aurora Cluster (Aurora PostgreSQL)

```hcl
module "aurora" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/rds?ref=v1.2.0"

  name_prefix        = "my-app-aurora"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true

  replica_count       = 2
  deletion_protection = true

  backup_retention_period = 14

  parameter_group_family = "aurora-postgresql15"

  performance_insights_enabled   = true
  performance_insights_retention = 731
  monitoring_interval            = 60

  enabled_cloudwatch_logs_exports = ["postgresql"]

  allowed_security_group_ids = [module.ecs.service_security_group_id]

  tags = {
    Project = "my-app"
  }
}
```

## VPC Integration

This module consumes an existing VPC — it does **not** create any networking resources. Pass in `vpc_id` and `private_subnet_ids` from any VPC module or data source. The DB subnet group is created from the private subnets, and all databases are configured with `publicly_accessible = false`.

```hcl
module "vpc" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/vpc?ref=v1.0.0"

  vpc_name    = "my-app"
  environment = "production"
}

module "rds" {
  source = "../../"

  name_prefix        = "my-app"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # ... database configuration ...
}
```

## Architecture

```
                          ┌─────────────────────────────────┐
                          │        VPC Module Outputs        │
                          │  vpc_id    private_subnet_ids    │
                          └──────┬──────────────┬───────────┘
                                 │              │
                    ┌────────────┘              └────────────┐
                    ▼                                        ▼
          ┌─────────────────┐                    ┌──────────────────┐
          │  Security Group  │                    │  DB Subnet Group  │
          │  (ingress from   │                    │  (private subnets │
          │   allowed SGs    │                    │   only)           │
          │   and CIDRs)     │                    └────────┬─────────┘
          └────────┬─────────┘                             │
                   │                                       │
                   └───────────┬───────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               │                               │
               ▼                               ▼
    ┌─────────────────────┐      ┌──────────────────────────┐
    │   Standard RDS       │      │   Aurora Cluster          │
    │   (postgres, mysql,  │      │   (aurora-postgresql,     │
    │    mariadb)          │      │    aurora-mysql)           │
    │                      │      │                           │
    │  - Multi-AZ          │      │  - Writer + N Readers     │
    │  - Storage autoscale │      │  - Automatic failover     │
    │  - Option groups     │      │  - Cluster param groups   │
    └─────────────────────┘      └──────────────────────────┘
               │                               │
               └───────────────┬───────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │  Downstream       │
                    │  (ECS, EKS, EC2,  │
                    │   Lambda)         │
                    └──────────────────┘
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Name prefix for all resources | `string` | — | yes |
| `environment` | Environment name (dev, staging, production) | `string` | — | yes |
| `engine` | Database engine (postgres, mysql, mariadb, aurora-postgresql, aurora-mysql) | `string` | — | yes |
| `engine_version` | Database engine version | `string` | — | yes |
| `instance_class` | Instance class (e.g. db.t3.medium, db.r6g.large) | `string` | — | yes |
| `cluster_mode` | Override auto-detection for cluster mode | `bool` | `null` | no |
| `database_name` | Database name to create | `string` | `null` | no |
| `master_username` | Master DB username | `string` | — | yes |
| `master_password` | Master DB password (mutually exclusive with manage_master_user_password) | `string` | `null` | no |
| `manage_master_user_password` | Let RDS manage password in Secrets Manager | `bool` | `false` | no |
| `master_user_secret_kms_key_id` | KMS key for Secrets Manager-managed password | `string` | `null` | no |
| `port` | Database port (auto-detected from engine if null) | `number` | `null` | no |
| `vpc_id` | VPC ID for security groups | `string` | — | yes |
| `private_subnet_ids` | Private subnet IDs for DB subnet group (minimum 2) | `list(string)` | — | yes |
| `allowed_security_group_ids` | Security group IDs allowed to connect | `list(string)` | `[]` | no |
| `allowed_cidr_blocks` | CIDR blocks allowed to connect | `list(string)` | `[]` | no |
| `allocated_storage` | Initial storage in GiB (standard RDS only) | `number` | `20` | no |
| `max_allocated_storage` | Max storage for autoscaling, 0 = disabled (standard RDS only) | `number` | `0` | no |
| `storage_type` | Storage type: gp2, gp3, io1, io2 (standard RDS only) | `string` | `"gp3"` | no |
| `storage_encrypted` | Enable storage encryption at rest | `bool` | `true` | no |
| `kms_key_id` | KMS key ARN for storage encryption | `string` | `null` | no |
| `iops` | Provisioned IOPS (io1, io2, gp3) | `number` | `null` | no |
| `storage_throughput` | Storage throughput in MiBps (gp3 only) | `number` | `null` | no |
| `multi_az` | Enable Multi-AZ (standard RDS only) | `bool` | `false` | no |
| `replica_count` | Number of Aurora cluster instances (minimum 1) | `number` | `1` | no |
| `backup_retention_period` | Days to retain automated backups | `number` | `7` | no |
| `backup_window` | Preferred backup window (UTC) | `string` | `"03:00-04:00"` | no |
| `maintenance_window` | Preferred maintenance window (UTC) | `string` | `"Mon:04:00-Mon:05:00"` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `true` | no |
| `skip_final_snapshot` | Skip final snapshot on destroy | `bool` | `false` | no |
| `final_snapshot_identifier` | Identifier for final snapshot | `string` | `null` | no |
| `performance_insights_enabled` | Enable Performance Insights | `bool` | `false` | no |
| `performance_insights_retention` | Performance Insights retention in days | `number` | `7` | no |
| `monitoring_interval` | Enhanced Monitoring interval (0 = disabled) | `number` | `0` | no |
| `enabled_cloudwatch_logs_exports` | Log types to export to CloudWatch | `list(string)` | `[]` | no |
| `parameter_group_family` | DB parameter group family | `string` | `null` | no |
| `db_parameters` | DB parameter overrides | `list(object)` | `[]` | no |
| `cluster_parameters` | Cluster parameter overrides (Aurora only) | `list(object)` | `[]` | no |
| `option_group_options` | Option group options (standard RDS only) | `list(object)` | `[]` | no |
| `auto_minor_version_upgrade` | Auto minor version upgrade | `bool` | `true` | no |
| `apply_immediately` | Apply changes immediately | `bool` | `false` | no |
| `publicly_accessible` | Public accessibility | `bool` | `false` | no |
| `copy_tags_to_snapshot` | Copy tags to snapshots | `bool` | `true` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_id` | RDS instance ID (standard RDS, null for Aurora) |
| `db_instance_arn` | RDS instance ARN (standard RDS, null for Aurora) |
| `db_instance_endpoint` | RDS instance endpoint — host:port (standard RDS, null for Aurora) |
| `db_instance_address` | RDS instance hostname (standard RDS, null for Aurora) |
| `cluster_id` | Aurora cluster ID (Aurora, null for standard RDS) |
| `cluster_arn` | Aurora cluster ARN (Aurora, null for standard RDS) |
| `cluster_endpoint` | Aurora writer endpoint (Aurora, null for standard RDS) |
| `cluster_reader_endpoint` | Aurora reader endpoint (Aurora, null for standard RDS) |
| `cluster_members` | List of Aurora cluster instance identifiers |
| `port` | Database port |
| `database_name` | Database name |
| `security_group_id` | Database security group ID |
| `db_subnet_group_name` | DB subnet group name |
| `db_subnet_group_arn` | DB subnet group ARN |
| `parameter_group_name` | DB parameter group name |
| `master_user_secret_arn` | Secrets Manager secret ARN (when manage_master_user_password is true) |

## Engine Modes

| Engine | Mode | HA Strategy | Storage |
|--------|------|-------------|---------|
| `postgres` | Standard RDS | Multi-AZ standby | gp2, gp3, io1, io2 with autoscaling |
| `mysql` | Standard RDS | Multi-AZ standby | gp2, gp3, io1, io2 with autoscaling |
| `mariadb` | Standard RDS | Multi-AZ standby | gp2, gp3, io1, io2 with autoscaling |
| `aurora-postgresql` | Aurora Cluster | Multi-instance replicas | Aurora distributed storage |
| `aurora-mysql` | Aurora Cluster | Multi-instance replicas | Aurora distributed storage |

## Best Practices

- **Secrets Manager** — Use `manage_master_user_password = true` instead of plaintext passwords
- **Encryption** — Storage encryption is enabled by default (`storage_encrypted = true`)
- **Private subnets** — All databases are deployed in private subnets with `publicly_accessible = false`
- **Least privilege** — Restrict access via `allowed_security_group_ids` from application layers only
- **Backups** — Default 7-day retention; use 14-35 days for production
- **Deletion protection** — Enabled by default to prevent accidental destruction
- **Performance Insights** — Enable for production workloads (7-day free tier)
- **Enhanced Monitoring** — Set `monitoring_interval` for granular OS-level metrics
- **Maintenance** — `apply_immediately = false` by default; changes apply during maintenance windows

## Examples

- [Dev environment](examples/dev/) — PostgreSQL single instance + MySQL instance, cost-optimized for development
- [Production environment](examples/production/) — Aurora PostgreSQL cluster + Aurora MySQL cluster, HA with monitoring

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS provider | >= 5.0 |
