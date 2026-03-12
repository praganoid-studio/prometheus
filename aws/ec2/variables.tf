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
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID where the EC2 resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Default list of subnet IDs for instance placement (public or private, depends on use case)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least 1 subnet ID is required."
  }
}

################################################################################
# Key Pair
################################################################################

variable "key_name" {
  description = "Name of an existing EC2 Key Pair for SSH access; shared default across all instance groups (overridable per group)"
  type        = string
  default     = ""
}

################################################################################
# Instances
################################################################################

variable "instances" {
  description = "Map of EC2 instance group configurations"
  type = map(object({
    # Instance configuration
    ami_id         = string
    instance_type  = optional(string, "t3.micro")
    key_name       = optional(string, "")
    subnet_ids     = optional(list(string), [])
    instance_count = optional(number, 1)

    # User data
    user_data        = optional(string, "")
    user_data_base64 = optional(string, "")

    # Root volume
    root_volume_size       = optional(number, 20)
    root_volume_type       = optional(string, "gp3")
    root_volume_iops       = optional(number, null)
    root_volume_throughput = optional(number, null)
    root_volume_encrypted  = optional(bool, true)
    root_volume_kms_key_id = optional(string, "")

    # Additional EBS volumes
    ebs_block_devices = optional(list(object({
      device_name = string
      volume_size = number
      volume_type = optional(string, "gp3")
      iops        = optional(number, null)
      throughput  = optional(number, null)
      encrypted   = optional(bool, true)
      kms_key_id  = optional(string, "")
    })), [])

    # Networking
    associate_public_ip_address = optional(bool, false)
    enable_eip                  = optional(bool, false)
    source_dest_check           = optional(bool, true)

    # IAM
    iam_policy_arns = optional(list(string), [])
    enable_ssm      = optional(bool, true)

    # Security
    additional_security_group_ids = optional(list(string), [])
    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string), [])
      source_security_group_id = optional(string, "")
      description              = optional(string, "")
    })), [])

    # Metadata options (IMDSv2)
    metadata_http_tokens = optional(string, "required")
    metadata_hop_limit   = optional(number, 1)

    # Monitoring
    monitoring = optional(bool, false)

    # Auto Scaling Group (optional)
    enable_asg                    = optional(bool, false)
    asg_min_size                  = optional(number, 1)
    asg_max_size                  = optional(number, 3)
    asg_desired_capacity          = optional(number, 1)
    asg_health_check_type         = optional(string, "EC2")
    asg_health_check_grace_period = optional(number, 300)
    asg_target_group_arns         = optional(list(string), [])
    asg_suspended_processes       = optional(list(string), [])
    asg_instance_refresh          = optional(bool, false)
    asg_instance_refresh_strategy = optional(string, "Rolling")
    asg_min_healthy_percentage    = optional(number, 90)

    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
