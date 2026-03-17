################################################################################
# RDS Instance (Standard)
################################################################################

output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = try(aws_db_instance.this[0].id, null)
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(aws_db_instance.this[0].arn, null)
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance (host:port)"
  value       = try(aws_db_instance.this[0].endpoint, null)
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = try(aws_db_instance.this[0].address, null)
}

################################################################################
# Aurora Cluster
################################################################################

output "cluster_id" {
  description = "The ID of the Aurora cluster"
  value       = try(aws_rds_cluster.this[0].id, null)
}

output "cluster_arn" {
  description = "The ARN of the Aurora cluster"
  value       = try(aws_rds_cluster.this[0].arn, null)
}

output "cluster_endpoint" {
  description = "The writer endpoint of the Aurora cluster"
  value       = try(aws_rds_cluster.this[0].endpoint, null)
}

output "cluster_reader_endpoint" {
  description = "The reader endpoint of the Aurora cluster (load-balanced across readers)"
  value       = try(aws_rds_cluster.this[0].reader_endpoint, null)
}

output "cluster_members" {
  description = "List of Aurora cluster instance identifiers"
  value       = try(aws_rds_cluster_instance.this[*].identifier, [])
}

################################################################################
# Common
################################################################################

output "port" {
  description = "The database port"
  value       = local.port
}

output "database_name" {
  description = "The name of the database"
  value       = var.database_name
}

output "security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

output "parameter_group_name" {
  description = "The name of the DB parameter group"
  value       = try(aws_db_parameter_group.this[0].name, null)
}

output "master_user_secret_arn" {
  description = "The ARN of the Secrets Manager secret for the master user password (when manage_master_user_password is true)"
  value = try(
    local.is_aurora ? aws_rds_cluster.this[0].master_user_secret[0].secret_arn : aws_db_instance.this[0].master_user_secret[0].secret_arn,
    null
  )
}
