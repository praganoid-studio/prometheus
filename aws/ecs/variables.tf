################################################################################
# Core
################################################################################

variable "cluster_name" {
  description = "Name of the ECS cluster, used as prefix for all resources"
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
  description = "VPC ID where the ECS resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS task placement"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs are required for ECS."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB placement. Required when enable_alb is true"
  type        = list(string)
  default     = []
}

################################################################################
# Capacity Providers
################################################################################

variable "capacity_providers" {
  description = "List of capacity providers to associate with the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]

  validation {
    condition     = length(var.capacity_providers) > 0
    error_message = "At least one capacity provider is required."
  }
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type = list(object({
    capacity_provider = string
    base              = optional(number, 0)
    weight            = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 100
    }
  ]
}

################################################################################
# Load Balancer
################################################################################

variable "enable_alb" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "alb_internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "alb_ssl_certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Leave empty to disable HTTPS"
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

################################################################################
# Services
################################################################################

variable "services" {
  description = "Map of ECS service configurations"
  type = map(object({
    # Task definition
    cpu                    = optional(number, 256)
    memory                 = optional(number, 512)
    container_definitions  = string
    task_role_policy_arns  = optional(list(string), [])
    enable_execute_command = optional(bool, false)

    # Service
    desired_count             = optional(number, 1)
    launch_type               = optional(string, "FARGATE")
    platform_version          = optional(string, "LATEST")
    force_new_deployment      = optional(bool, true)
    deployment_min_percent    = optional(number, 100)
    deployment_max_percent    = optional(number, 200)
    health_check_grace_period = optional(number, 30)
    assign_public_ip          = optional(bool, false)
    service_subnet_ids        = optional(list(string), [])

    # Load balancer
    enable_load_balancer = optional(bool, false)
    container_name       = optional(string, "")
    container_port       = optional(number, 80)
    health_check_path    = optional(string, "/")
    health_check_matcher = optional(string, "200")
    listener_priority    = optional(number, null)

    # Auto scaling
    enable_autoscaling        = optional(bool, false)
    autoscaling_min_capacity  = optional(number, 1)
    autoscaling_max_capacity  = optional(number, 10)
    autoscaling_cpu_target    = optional(number, 70)
    autoscaling_memory_target = optional(number, 80)

    # Logging
    log_retention_days = optional(number, 30)

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
