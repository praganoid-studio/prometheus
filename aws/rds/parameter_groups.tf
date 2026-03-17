################################################################################
# DB Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  count = var.parameter_group_family != null ? 1 : 0

  name   = "${local.name_prefix}-db-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Cluster Parameter Group (Aurora Only)
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.parameter_group_family != null && local.is_aurora ? 1 : 0

  name   = "${local.name_prefix}-cluster-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Option Group (Standard RDS Only)
################################################################################

resource "aws_db_option_group" "this" {
  count = !local.is_aurora && length(var.option_group_options) > 0 ? 1 : 0

  name                 = "${local.name_prefix}-db-options"
  engine_name          = var.engine
  major_engine_version = regex("^\\d+", var.engine_version)

  dynamic "option" {
    for_each = var.option_group_options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-options"
  })

  lifecycle {
    create_before_destroy = true
  }
}
