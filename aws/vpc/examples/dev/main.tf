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

module "vpc" {
  source = "../../"

  vpc_name       = var.vpc_name
  environment    = var.environment
  vpc_cidr_block = var.vpc_cidr_block

  public_subnet_count  = 2
  private_subnet_count = 2
  single_nat_gateway   = true

  tags = var.tags
}
