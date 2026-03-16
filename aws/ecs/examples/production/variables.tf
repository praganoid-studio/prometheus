variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "alb_ssl_certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener"
  type        = string
  default     = ""
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
