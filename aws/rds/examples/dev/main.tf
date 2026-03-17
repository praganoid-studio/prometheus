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
# PostgreSQL Single Instance
################################################################################

module "postgres" {
  source = "../../"

  name_prefix        = "${var.name_prefix}-pg"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true

  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  allowed_cidr_blocks = [var.vpc_cidr_block]

  tags = var.tags
}

################################################################################
# MySQL Single Instance
################################################################################

module "mysql" {
  source = "../../"

  name_prefix        = "${var.name_prefix}-mysql"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true

  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  allowed_cidr_blocks = [var.vpc_cidr_block]

  tags = var.tags
}
