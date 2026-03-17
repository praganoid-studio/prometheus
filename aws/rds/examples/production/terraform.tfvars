aws_region     = "us-east-1"
name_prefix    = "myapp-prod"
environment    = "production"
vpc_cidr_block = "10.2.0.0/16"

tags = {
  Project = "myapp"
  Owner   = "devops"
}
