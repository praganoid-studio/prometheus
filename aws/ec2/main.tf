################################################################################
# Launch Templates
################################################################################

resource "aws_launch_template" "this" {
  for_each = var.instances

  name = "${local.name_prefix}-${each.key}-lt"

  image_id      = each.value.ami_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name != "" ? each.value.key_name : (var.key_name != "" ? var.key_name : null)

  user_data = each.value.user_data_base64 != "" ? each.value.user_data_base64 : (
    each.value.user_data != "" ? base64encode(each.value.user_data) : null
  )

  vpc_security_group_ids = concat(
    [aws_security_group.this[each.key].id],
    each.value.additional_security_group_ids
  )

  iam_instance_profile {
    arn = aws_iam_instance_profile.this[each.key].arn
  }

  metadata_options {
    http_tokens                 = each.value.metadata_http_tokens
    http_put_response_hop_limit = each.value.metadata_hop_limit
    http_endpoint               = "enabled"
  }

  monitoring {
    enabled = each.value.monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.root_volume_size
      volume_type           = each.value.root_volume_type
      iops                  = each.value.root_volume_iops
      throughput            = each.value.root_volume_throughput
      encrypted             = each.value.root_volume_encrypted
      kms_key_id            = each.value.root_volume_kms_key_id != "" ? each.value.root_volume_kms_key_id : null
      delete_on_termination = true
    }
  }

  dynamic "block_device_mappings" {
    for_each = each.value.ebs_block_devices

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        iops                  = block_device_mappings.value.iops
        throughput            = block_device_mappings.value.throughput
        encrypted             = block_device_mappings.value.encrypted
        kms_key_id            = block_device_mappings.value.kms_key_id != "" ? block_device_mappings.value.kms_key_id : null
        delete_on_termination = true
      }
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, each.value.tags, {
      Name  = "${local.name_prefix}-${each.key}"
      Group = each.key
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, each.value.tags, {
      Name  = "${local.name_prefix}-${each.key}"
      Group = each.key
    })
  }

  tags = merge(local.common_tags, each.value.tags, {
    Name  = "${local.name_prefix}-${each.key}-lt"
    Group = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# EC2 Instances (standalone, non-ASG groups)
################################################################################

resource "aws_instance" "this" {
  for_each = local.instance_fleet

  subnet_id         = each.value.subnet_id
  source_dest_check = var.instances[each.value.group_key].source_dest_check

  launch_template {
    id      = aws_launch_template.this[each.value.group_key].id
    version = aws_launch_template.this[each.value.group_key].latest_version
  }

  associate_public_ip_address = var.instances[each.value.group_key].associate_public_ip_address

  tags = merge(local.common_tags, var.instances[each.value.group_key].tags, {
    Name  = "${local.name_prefix}-${each.value.group_key}-${each.value.index}"
    Group = each.value.group_key
  })
}
