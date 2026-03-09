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

  public_subnet_count  = 3
  private_subnet_count = 3
  single_nat_gateway   = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

################################################################################
# EKS
################################################################################

module "eks" {
  source = "../../"

  cluster_name       = var.cluster_name
  environment        = var.environment
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = var.public_access_cidrs

  enabled_cluster_log_types      = ["api", "audit", "authenticator"]
  cluster_encryption_kms_key_arn = var.cluster_encryption_kms_key_arn

  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      min_size       = 2
      max_size       = 10
      desired_size   = 3

      labels = {
        Environment = "production"
        Role        = "general"
      }
    }

    compute = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["c5.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      min_size       = 0
      max_size       = 5
      desired_size   = 0

      labels = {
        Environment = "production"
        Role        = "compute"
      }

      taints = [
        {
          key    = "dedicated"
          value  = "compute"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  fargate_profiles = {
    kube-system = {
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "coredns"
          }
        }
      ]
    }
  }

  tags = var.tags
}
