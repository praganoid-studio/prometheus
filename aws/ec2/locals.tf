locals {
  name_prefix = var.name_prefix
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.id

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ec2"
  })

  # Instance groups that use standalone instances (not ASG)
  standalone_instances = {
    for k, v in var.instances : k => v if !v.enable_asg
  }

  # Instance groups that use ASG
  asg_instances = {
    for k, v in var.instances : k => v if v.enable_asg
  }

  # Flatten standalone instances for aws_instance for_each: "group-0", "group-1", etc.
  instance_fleet = merge([
    for group_key, group in local.standalone_instances : {
      for idx in range(group.instance_count) :
      "${group_key}-${idx}" => {
        group_key = group_key
        index     = idx
        subnet_id = element(
          length(group.subnet_ids) > 0 ? group.subnet_ids : var.subnet_ids,
          idx
        )
      }
    }
  ]...)

  # Flatten EIP instances
  eip_instances = {
    for k, v in local.instance_fleet : k => v
    if local.standalone_instances[v.group_key].enable_eip
  }

  # Flatten IAM policy attachments
  iam_policy_attachments = merge([
    for group_key, group in var.instances : {
      for idx, arn in group.iam_policy_arns :
      "${group_key}-${idx}" => {
        group_key  = group_key
        policy_arn = arn
      }
    }
  ]...)

  # SSM-enabled groups
  ssm_groups = {
    for k, v in var.instances : k => v if v.enable_ssm
  }
}
