################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

################################################################################
# PostgreSQL
################################################################################

output "postgres_endpoint" {
  description = "PostgreSQL instance endpoint"
  value       = module.postgres.db_instance_endpoint
}

output "postgres_port" {
  description = "PostgreSQL instance port"
  value       = module.postgres.port
}

output "postgres_security_group_id" {
  description = "PostgreSQL security group ID"
  value       = module.postgres.security_group_id
}

output "postgres_master_user_secret_arn" {
  description = "PostgreSQL Secrets Manager secret ARN"
  value       = module.postgres.master_user_secret_arn
}

################################################################################
# MySQL
################################################################################

output "mysql_endpoint" {
  description = "MySQL instance endpoint"
  value       = module.mysql.db_instance_endpoint
}

output "mysql_port" {
  description = "MySQL instance port"
  value       = module.mysql.port
}

output "mysql_security_group_id" {
  description = "MySQL security group ID"
  value       = module.mysql.security_group_id
}

output "mysql_master_user_secret_arn" {
  description = "MySQL Secrets Manager secret ARN"
  value       = module.mysql.master_user_secret_arn
}
