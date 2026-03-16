variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "app_ami_id" {
  description = "AMI ID for the application instances"
  type        = string
}

variable "worker_ami_id" {
  description = "AMI ID for the worker instances"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host"
  type        = list(string)
}

variable "app_iam_policy_arns" {
  description = "IAM policy ARNs to attach to the app instance role"
  type        = list(string)
  default     = []
}

variable "worker_iam_policy_arns" {
  description = "IAM policy ARNs to attach to the worker instance role"
  type        = list(string)
  default     = []
}

variable "app_target_group_arns" {
  description = "Target group ARNs for the app ASG"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
