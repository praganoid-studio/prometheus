variable "vpc_name" {
  description = "Name prefix for all resources created by this module"
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

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid CIDR block."
  }
}

variable "azs" {
  description = "List of availability zones. If empty, zones are auto-detected"
  type        = list(string)
  default     = []
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 6
    error_message = "public_subnet_count must be between 1 and 6."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3

  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 6
    error_message = "private_subnet_count must be between 1 and 6."
  }
}

variable "public_subnet_newbits" {
  description = "Newbits value for cidrsubnet() when creating public subnets. Controls subnet size relative to VPC CIDR"
  type        = number
  default     = 8
}

variable "private_subnet_newbits" {
  description = "Newbits value for cidrsubnet() when creating private subnets. Controls subnet size relative to VPC CIDR"
  type        = number
  default     = 8
}

variable "public_subnet_offset" {
  description = "Starting netnum offset for cidrsubnet() for public subnets"
  type        = number
  default     = 0
}

variable "private_subnet_offset" {
  description = "Starting netnum offset for cidrsubnet() for private subnets"
  type        = number
  default     = 10
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway instead of one per AZ (cost saving for non-prod)"
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Request an Amazon-provided IPv6 CIDR block for the VPC"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP addresses to instances launched in public subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets only (e.g. kubernetes.io/role/elb for EKS)"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets only (e.g. kubernetes.io/role/internal-elb for EKS)"
  type        = map(string)
  default     = {}
}
