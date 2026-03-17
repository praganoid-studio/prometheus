################################################################################
# Core
################################################################################

variable "name_prefix" {
  description = "Name prefix for all resources, used as naming convention base"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

################################################################################
# Engine Configuration
################################################################################

variable "engine" {
  description = "Database engine type (e.g. postgres, mysql, mariadb, aurora-postgresql, aurora-mysql)"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "aurora-postgresql", "aurora-mysql"], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "instance_class" {
  description = "The instance class for the RDS instance or Aurora cluster instances (e.g. db.t3.medium, db.r6g.large)"
  type        = string
}

variable "cluster_mode" {
  description = "Explicit override for cluster mode; null = auto-detected from engine (aurora-* engines create clusters)"
  type        = bool
  default     = null
}

################################################################################
# Database Configuration
################################################################################

variable "database_name" {
  description = "Name of the database to create when the instance/cluster is created"
  type        = string
  default     = null
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "master_password" {
  description = "Password for the master DB user; mutually exclusive with manage_master_user_password"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "master_user_secret_kms_key_id" {
  description = "KMS key ID for encrypting the Secrets Manager-managed master user password"
  type        = string
  default     = null
}

variable "port" {
  description = "Database port; defaults to 5432 for PostgreSQL engines, 3306 for MySQL/MariaDB"
  type        = number
  default     = null
}

################################################################################
# Storage (Standard RDS Only)
################################################################################

variable "allocated_storage" {
  description = "Initial allocated storage in GiB (standard RDS only)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GiB for autoscaling (0 = disabled, standard RDS only)"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type: gp2, gp3, io1, io2 (standard RDS only)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2."
  }
}

variable "storage_encrypted" {
  description = "Enable storage encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key for storage encryption"
  type        = string
  default     = null
}

variable "iops" {
  description = "Provisioned IOPS for io1, io2, or gp3 storage types"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput in MiBps (gp3 only)"
  type        = number
  default     = null
}

################################################################################
# High Availability
################################################################################

variable "multi_az" {
  description = "Enable Multi-AZ deployment for standard RDS instances"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of Aurora cluster instances (writer + readers); minimum 1"
  type        = number
  default     = 1

  validation {
    condition     = var.replica_count >= 1
    error_message = "Replica count must be at least 1."
  }
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs are required for the DB subnet group."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

################################################################################
# Backup and Maintenance
################################################################################

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred daily window for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred weekly window for system maintenance (UTC)"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection to prevent accidental database destruction"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip creation of a final snapshot when destroying the database"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot on deletion; auto-generated from name_prefix if null"
  type        = string
  default     = null
}

################################################################################
# Monitoring
################################################################################

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention" {
  description = "Performance Insights data retention period in days (7 = free tier, 731 = 2 years)"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 = disabled; valid: 0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (e.g. postgresql, audit, error, general, slowquery)"
  type        = list(string)
  default     = []
}

################################################################################
# Parameter and Option Groups
################################################################################

variable "parameter_group_family" {
  description = "DB parameter group family (e.g. postgres15, aurora-postgresql15); required if db_parameters or cluster_parameters are set"
  type        = string
  default     = null
}

variable "db_parameters" {
  description = "List of DB parameter overrides"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = []
}

variable "cluster_parameters" {
  description = "List of cluster parameter overrides (Aurora only)"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = []
}

variable "option_group_options" {
  description = "List of option group options (standard RDS only)"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

################################################################################
# Miscellaneous
################################################################################

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor engine version upgrades during the maintenance window"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the next maintenance window"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible (should always be false for private subnet deployment)"
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Copy all tags to snapshots"
  type        = bool
  default     = true
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
