################################################################################
# Instances
################################################################################

output "instance_ids" {
  description = "Map of group name to list of instance IDs (empty for ASG groups)"
  value = {
    for group_key in keys(local.standalone_instances) : group_key => [
      for k, v in aws_instance.this : v.id if v.tags["Group"] == group_key
    ]
  }
}

output "instance_private_ips" {
  description = "Map of group name to list of private IP addresses"
  value = {
    for group_key in keys(local.standalone_instances) : group_key => [
      for k, v in aws_instance.this : v.private_ip if v.tags["Group"] == group_key
    ]
  }
}

output "instance_public_ips" {
  description = "Map of group name to list of public IP addresses"
  value = {
    for group_key in keys(local.standalone_instances) : group_key => [
      for k, v in aws_instance.this : v.public_ip if v.tags["Group"] == group_key
    ]
  }
}

################################################################################
# Launch Templates
################################################################################

output "launch_template_ids" {
  description = "Map of group name to Launch Template ID"
  value = {
    for k, v in aws_launch_template.this : k => v.id
  }
}

output "launch_template_latest_versions" {
  description = "Map of group name to latest Launch Template version"
  value = {
    for k, v in aws_launch_template.this : k => v.latest_version
  }
}

################################################################################
# IAM
################################################################################

output "instance_profile_arns" {
  description = "Map of group name to instance profile ARN"
  value = {
    for k, v in aws_iam_instance_profile.this : k => v.arn
  }
}

output "iam_role_arns" {
  description = "Map of group name to IAM role ARN"
  value = {
    for k, v in aws_iam_role.this : k => v.arn
  }
}

################################################################################
# Security Groups
################################################################################

output "security_group_ids" {
  description = "Map of group name to security group ID"
  value = {
    for k, v in aws_security_group.this : k => v.id
  }
}

################################################################################
# Elastic IPs
################################################################################

output "eip_public_ips" {
  description = "Map of group name to list of Elastic IP addresses (only for groups with enable_eip = true)"
  value = {
    for group_key in keys(local.standalone_instances) : group_key => [
      for k, v in aws_eip.this : v.public_ip if local.eip_instances[k].group_key == group_key
    ] if lookup(local.standalone_instances[group_key], "enable_eip", false)
  }
}

################################################################################
# Auto Scaling Groups
################################################################################

output "asg_arns" {
  description = "Map of group name to ASG ARN (only for groups with enable_asg = true)"
  value = {
    for k, v in aws_autoscaling_group.this : k => v.arn
  }
}

output "asg_names" {
  description = "Map of group name to ASG name"
  value = {
    for k, v in aws_autoscaling_group.this : k => v.name
  }
}
