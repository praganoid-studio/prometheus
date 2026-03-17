################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

################################################################################
# Standard RDS Instance
################################################################################

resource "aws_db_instance" "this" {
  count = local.is_aurora ? 0 : 1

  identifier = "${local.name_prefix}-db"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  iops                  = var.iops
  storage_throughput    = var.storage_throughput

  db_name  = var.database_name
  username = var.master_username
  password = var.manage_master_user_password ? null : var.master_password
  port     = local.port

  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  multi_az             = var.multi_az
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible

  parameter_group_name = var.parameter_group_family != null ? aws_db_parameter_group.this[0].name : null
  option_group_name    = length(var.option_group_options) > 0 ? aws_db_option_group.this[0].name : null

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.enhanced_monitoring_enabled ? aws_iam_role.enhanced_monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db"
  })
}

################################################################################
# Aurora RDS Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  count = local.is_aurora ? 1 : 0

  cluster_identifier = "${local.name_prefix}-cluster"

  engine         = var.engine
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.manage_master_user_password ? null : var.master_password
  port            = local.port

  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  db_cluster_parameter_group_name = var.parameter_group_family != null ? aws_rds_cluster_parameter_group.this[0].name : null

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot

  apply_immediately = var.apply_immediately

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster"
  })
}

################################################################################
# Aurora Cluster Instances
################################################################################

resource "aws_rds_cluster_instance" "this" {
  count = local.is_aurora ? var.replica_count : 0

  identifier         = "${local.name_prefix}-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.this[0].id

  engine         = aws_rds_cluster.this[0].engine
  engine_version = aws_rds_cluster.this[0].engine_version
  instance_class = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible

  db_parameter_group_name = var.parameter_group_family != null ? aws_db_parameter_group.this[0].name : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.enhanced_monitoring_enabled ? aws_iam_role.enhanced_monitoring[0].arn : null

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster-${count.index}"
  })
}
