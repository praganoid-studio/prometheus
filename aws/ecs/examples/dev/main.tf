terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source = "../../../vpc/"

  vpc_name       = var.cluster_name
  environment    = var.environment
  vpc_cidr_block = var.vpc_cidr_block

  public_subnet_count  = 2
  private_subnet_count = 2
  single_nat_gateway   = true

  tags = var.tags
}

################################################################################
# ECS
################################################################################

module "ecs" {
  source = "../../"

  cluster_name       = var.cluster_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  enable_alb = true

  services = {
    api = {
      cpu    = 256
      memory = 512
      container_definitions = jsonencode([{
        name      = "api"
        image     = "nginx:latest"
        essential = true
        portMappings = [{
          containerPort = 80
          protocol      = "tcp"
        }]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.cluster_name}/api"
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }])

      desired_count        = 1
      enable_load_balancer = true
      container_name       = "api"
      container_port       = 80
      health_check_path    = "/"

      enable_autoscaling       = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 3
      autoscaling_cpu_target   = 70

      log_retention_days = 7
    }
  }

  tags = var.tags
}
