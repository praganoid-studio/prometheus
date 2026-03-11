# AWS ECS Terraform Module

A production-ready, reusable Terraform module for provisioning an AWS ECS cluster with multiple services, Fargate/EC2 capacity providers, optional Application Load Balancer, auto scaling, IAM roles, security groups, and CloudWatch logging. Designed for consumption by API services, background workers, queue processors, and other microservice workloads.

## Features

- ECS cluster with configurable capacity providers (Fargate, Fargate Spot, EC2 ASG)
- Multiple services via `for_each` — each with its own task definition, IAM role, security group, and log group
- Shared task execution role (for ECR image pulls and log writes)
- Per-service task roles with configurable policy attachments
- Optional Application Load Balancer with HTTP/HTTPS listeners and per-service target groups
- Per-service security groups with ALB ingress and custom rules
- Application Auto Scaling with CPU and memory target tracking policies
- Per-service CloudWatch log groups with configurable retention
- Deployment circuit breaker with automatic rollback
- Container Insights enabled on the cluster
- Consistent resource tagging strategy

## Usage

```hcl
module "ecs" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/ecs?ref=v1.2.0"

  cluster_name       = "my-cluster"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  enable_alb              = true
  alb_ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"

  services = {
    api = {
      cpu    = 1024
      memory = 2048
      container_definitions = jsonencode([{
        name      = "api"
        image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-api:latest"
        essential = true
        portMappings = [{
          containerPort = 8080
          protocol      = "tcp"
        }]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/my-cluster/api"
            "awslogs-region"        = "us-east-1"
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }])

      enable_load_balancer = true
      container_name       = "api"
      container_port       = 8080
      health_check_path    = "/health"

      enable_autoscaling       = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 20
    }
  }

  tags = {
    Project = "my-app"
  }
}
```

## VPC Integration

This module consumes an existing VPC — it does **not** create any networking resources. Pass in `vpc_id`, `private_subnet_ids`, and `public_subnet_ids` from any VPC module or data source.

```hcl
module "vpc" {
  source = "git::https://github.com/praganoid-studio/infra-prometheus.git//aws/vpc?ref=v1.0.0"

  vpc_name    = "ecs-cluster"
  environment = "production"
}

module "ecs" {
  source = "../../"

  cluster_name       = "my-cluster"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name of the ECS cluster | `string` | — | yes |
| `environment` | Environment name (dev, staging, production) | `string` | — | yes |
| `vpc_id` | VPC ID for security groups | `string` | — | yes |
| `private_subnet_ids` | Private subnet IDs for task placement (minimum 2) | `list(string)` | — | yes |
| `public_subnet_ids` | Public subnet IDs for ALB | `list(string)` | `[]` | no |
| `capacity_providers` | Capacity providers for the cluster | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` | no |
| `default_capacity_provider_strategy` | Default capacity provider strategy | `list(object)` | FARGATE base=1 weight=100 | no |
| `enable_alb` | Create an Application Load Balancer | `bool` | `true` | no |
| `alb_internal` | Whether the ALB is internal | `bool` | `false` | no |
| `alb_idle_timeout` | ALB idle timeout in seconds | `number` | `60` | no |
| `alb_ssl_certificate_arn` | ACM certificate ARN for HTTPS | `string` | `""` | no |
| `alb_ssl_policy` | SSL policy for HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| `alb_ingress_cidr_blocks` | CIDRs allowed to access the ALB | `list(string)` | `["0.0.0.0/0"]` | no |
| `services` | Map of ECS service configurations | `map(object)` | `{}` | no |
| `tags` | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | The ECS cluster ID |
| `cluster_arn` | The ECS cluster ARN |
| `cluster_name` | The ECS cluster name |
| `service_arns` | Map of service name to service ARN |
| `service_names` | Map of service name to ECS service name |
| `task_definition_arns` | Map of service name to task definition ARN |
| `service_security_group_ids` | Map of service name to security group ID |
| `task_execution_role_arn` | Shared task execution IAM role ARN |
| `task_role_arns` | Map of service name to task IAM role ARN |
| `alb_arn` | ALB ARN |
| `alb_dns_name` | ALB DNS name |
| `alb_zone_id` | ALB hosted zone ID (for Route53 alias) |
| `alb_security_group_id` | ALB security group ID |
| `target_group_arns` | Map of service name to target group ARN |
| `http_listener_arn` | HTTP listener ARN |
| `https_listener_arn` | HTTPS listener ARN |
| `log_group_names` | Map of service name to CloudWatch log group name |
| `log_group_arns` | Map of service name to CloudWatch log group ARN |

## Service Configuration

Each entry in `services` supports:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cpu` | `number` | `256` | Task CPU units |
| `memory` | `number` | `512` | Task memory (MiB) |
| `container_definitions` | `string` | — | JSON-encoded container definitions |
| `task_role_policy_arns` | `list(string)` | `[]` | IAM policy ARNs for the task role |
| `enable_execute_command` | `bool` | `false` | Enable ECS Exec |
| `desired_count` | `number` | `1` | Desired task count |
| `launch_type` | `string` | `"FARGATE"` | FARGATE or EC2 |
| `platform_version` | `string` | `"LATEST"` | Fargate platform version |
| `force_new_deployment` | `bool` | `true` | Force new deployment on apply |
| `deployment_min_percent` | `number` | `100` | Minimum healthy percent |
| `deployment_max_percent` | `number` | `200` | Maximum percent during deployment |
| `health_check_grace_period` | `number` | `30` | Seconds before health check starts |
| `assign_public_ip` | `bool` | `false` | Assign public IP to tasks |
| `service_subnet_ids` | `list(string)` | `[]` | Override subnet IDs (defaults to private_subnet_ids) |
| `enable_load_balancer` | `bool` | `false` | Register with ALB target group |
| `container_name` | `string` | `""` | Container name for ALB target |
| `container_port` | `number` | `80` | Container port for ALB target |
| `health_check_path` | `string` | `"/"` | Health check path |
| `health_check_matcher` | `string` | `"200"` | Expected health check response codes |
| `listener_priority` | `number` | `null` | ALB listener rule priority |
| `enable_autoscaling` | `bool` | `false` | Enable Application Auto Scaling |
| `autoscaling_min_capacity` | `number` | `1` | Minimum task count |
| `autoscaling_max_capacity` | `number` | `10` | Maximum task count |
| `autoscaling_cpu_target` | `number` | `70` | CPU utilization target (%) |
| `autoscaling_memory_target` | `number` | `80` | Memory utilization target (%) |
| `log_retention_days` | `number` | `30` | CloudWatch log retention |
| `additional_security_group_ids` | `list(string)` | `[]` | Extra security groups for the service |
| `ingress_rules` | `list(object)` | `[]` | Custom ingress rules |
| `tags` | `map(string)` | `{}` | Additional tags |

## Service Patterns

| Pattern | load_balancer | autoscaling | Example |
|---------|---------------|-------------|---------|
| API service | yes | yes | REST/GraphQL API behind ALB |
| Background worker | no | yes | Queue consumer, stream processor |
| Scheduled task | no | no | Cron job (trigger via EventBridge) |
| Internal service | no | optional | Service-to-service communication |

## Examples

- [Dev environment](examples/dev/) — Single API service, SPOT-friendly, cost-optimized, short log retention
- [Production environment](examples/production/) — Multiple services (API + worker), HTTPS, auto scaling, extended log retention

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS provider | >= 5.0 |
