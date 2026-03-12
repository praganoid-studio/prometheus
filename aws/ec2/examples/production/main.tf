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

  vpc_name       = var.name_prefix
  environment    = var.environment
  vpc_cidr_block = var.vpc_cidr_block

  public_subnet_count  = 3
  private_subnet_count = 3
  single_nat_gateway   = false

  tags = var.tags
}

################################################################################
# EC2
################################################################################

module "ec2" {
  source = "../../"

  name_prefix = var.name_prefix
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  instances = {
    bastion = {
      ami_id         = var.bastion_ami_id
      instance_type  = "t3.micro"
      subnet_ids     = module.vpc.public_subnet_ids
      instance_count = 1

      associate_public_ip_address = true
      enable_eip                  = true

      user_data = templatefile("${path.module}/scripts/bastion.sh", {
        environment = var.environment
      })

      ingress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = var.ssh_allowed_cidrs
          description = "SSH access from allowed CIDRs"
        }
      ]
    }

    app = {
      ami_id        = var.app_ami_id
      instance_type = "t3.large"

      root_volume_size = 50
      monitoring       = true

      user_data = templatefile("${path.module}/scripts/app.sh", {
        environment = var.environment
        region      = var.aws_region
      })

      iam_policy_arns = var.app_iam_policy_arns

      ingress_rules = [
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr_block]
          description = "App port from VPC"
        }
      ]

      enable_asg           = true
      asg_min_size         = 2
      asg_max_size         = 10
      asg_desired_capacity = 3

      asg_health_check_type         = "ELB"
      asg_health_check_grace_period = 600
      asg_target_group_arns         = var.app_target_group_arns

      asg_instance_refresh      = true
      asg_min_healthy_percentage = 90
    }

    worker = {
      ami_id        = var.worker_ami_id
      instance_type = "t3.medium"

      root_volume_size = 40
      monitoring       = true

      ebs_block_devices = [
        {
          device_name = "/dev/xvdb"
          volume_size = 100
          volume_type = "gp3"
        }
      ]

      user_data = templatefile("${path.module}/scripts/app.sh", {
        environment = var.environment
        region      = var.aws_region
      })

      iam_policy_arns = var.worker_iam_policy_arns

      enable_asg           = true
      asg_min_size         = 1
      asg_max_size         = 5
      asg_desired_capacity = 2

      asg_instance_refresh       = true
      asg_min_healthy_percentage = 75
    }
  }

  tags = var.tags
}
