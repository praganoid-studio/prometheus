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
# Aurora PostgreSQL Cluster
################################################################################

module "aurora_postgres" {
  source = "../../"

  name_prefix        = "${var.name_prefix}-aurora-pg"
  environment        = var.environment
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
  skip_final_snapshot = false

  backup_retention_period = 14

  storage_encrypted = true

  parameter_group_family = "aurora-postgresql15"

  performance_insights_enabled   = true
  performance_insights_retention = 731
  monitoring_interval            = 60

  enabled_cloudwatch_logs_exports = ["postgresql"]

  allowed_cidr_blocks = [var.vpc_cidr_block]

  tags = var.tags
}

################################################################################
# Aurora MySQL Cluster
################################################################################

module "aurora_mysql" {
  source = "../../"

  name_prefix        = "${var.name_prefix}-aurora-mysql"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.04.1"
  instance_class = "db.r6g.large"

  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true

  replica_count       = 2
  deletion_protection = true
  skip_final_snapshot = false

  backup_retention_period = 14

  storage_encrypted = true

  parameter_group_family = "aurora-mysql8.0"

  performance_insights_enabled   = true
  performance_insights_retention = 731
  monitoring_interval            = 60

  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]

  allowed_cidr_blocks = [var.vpc_cidr_block]

  tags = var.tags
}
