################################################################################
# Core
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster, used as prefix for all resources"
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

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for node groups and default cluster networking"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for EKS."
  }
}

variable "control_plane_subnet_ids" {
  description = "Optional separate subnet IDs for EKS control plane ENIs. Defaults to subnet_ids if empty"
  type        = list(string)
  default     = []
}

################################################################################
# Cluster Endpoint Access
################################################################################

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

################################################################################
# Logging
################################################################################

variable "enabled_cluster_log_types" {
  description = "List of control plane log types to enable (e.g. api, audit, authenticator, controllerManager, scheduler)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Valid log types are: api, audit, authenticator, controllerManager, scheduler."
  }
}

################################################################################
# Encryption
################################################################################

variable "cluster_encryption_kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption. Disabled if empty"
  type        = string
  default     = ""
}

################################################################################
# Managed Node Groups
################################################################################

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    instance_types = optional(list(string), ["m5.large"])
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    min_size       = optional(number, 1)
    max_size       = optional(number, 3)
    desired_size   = optional(number, 2)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Fargate Profiles
################################################################################

variable "fargate_profiles" {
  description = "Map of Fargate profile configurations"
  type = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    subnet_ids = optional(list(string), [])
  }))
  default = {}
}

################################################################################
# Addons
################################################################################

variable "cluster_addons" {
  description = "Map of EKS addon configurations. Keys are addon names (e.g. coredns, kube-proxy, vpc-cni)"
  type = map(object({
    addon_version               = optional(string, null)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
    before_compute              = optional(bool, false)
  }))
  default = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }
}

################################################################################
# Access / Auth
################################################################################

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the Terraform caller admin access to the EKS cluster via access entries"
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Map of additional IAM principal access entries for the EKS cluster"
  type = map(object({
    principal_arn           = string
    policy_arn              = string
    access_scope_type       = string
    access_scope_namespaces = optional(list(string), [])
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
