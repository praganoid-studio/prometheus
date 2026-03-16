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

  public_subnet_count  = 2
  private_subnet_count = 2
  single_nat_gateway   = true

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
          description = "SSH access"
        }
      ]
    }

    app = {
      ami_id         = var.app_ami_id
      instance_type  = "t3.small"
      instance_count = 2

      root_volume_size = 30

      user_data = templatefile("${path.module}/scripts/app.sh", {
        environment = var.environment
        region      = var.aws_region
      })

      ingress_rules = [
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr_block]
          description = "App port from VPC"
        }
      ]
    }
  }

  tags = var.tags
}
