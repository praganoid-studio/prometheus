################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

################################################################################
# Aurora PostgreSQL
################################################################################

output "aurora_postgres_cluster_endpoint" {
  description = "Aurora PostgreSQL writer endpoint"
  value       = module.aurora_postgres.cluster_endpoint
}

output "aurora_postgres_reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint"
  value       = module.aurora_postgres.cluster_reader_endpoint
}

output "aurora_postgres_port" {
  description = "Aurora PostgreSQL port"
  value       = module.aurora_postgres.port
}

output "aurora_postgres_security_group_id" {
  description = "Aurora PostgreSQL security group ID"
  value       = module.aurora_postgres.security_group_id
}

output "aurora_postgres_master_user_secret_arn" {
  description = "Aurora PostgreSQL Secrets Manager secret ARN"
  value       = module.aurora_postgres.master_user_secret_arn
}

output "aurora_postgres_cluster_members" {
  description = "Aurora PostgreSQL cluster instance identifiers"
  value       = module.aurora_postgres.cluster_members
}

################################################################################
# Aurora MySQL
################################################################################

output "aurora_mysql_cluster_endpoint" {
  description = "Aurora MySQL writer endpoint"
  value       = module.aurora_mysql.cluster_endpoint
}

output "aurora_mysql_reader_endpoint" {
  description = "Aurora MySQL reader endpoint"
  value       = module.aurora_mysql.cluster_reader_endpoint
}

output "aurora_mysql_port" {
  description = "Aurora MySQL port"
  value       = module.aurora_mysql.port
}

output "aurora_mysql_security_group_id" {
  description = "Aurora MySQL security group ID"
  value       = module.aurora_mysql.security_group_id
}

output "aurora_mysql_master_user_secret_arn" {
  description = "Aurora MySQL Secrets Manager secret ARN"
  value       = module.aurora_mysql.master_user_secret_arn
}

output "aurora_mysql_cluster_members" {
  description = "Aurora MySQL cluster instance identifiers"
  value       = module.aurora_mysql.cluster_members
}
