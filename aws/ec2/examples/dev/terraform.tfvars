aws_region     = "us-east-1"
name_prefix    = "myapp-dev"
environment    = "dev"
vpc_cidr_block = "10.0.0.0/16"

bastion_ami_id = "ami-0123456789abcdef0"
app_ami_id     = "ami-0123456789abcdef0"

ssh_allowed_cidrs = ["203.0.113.0/24"]

tags = {
  Project = "myapp"
  Owner   = "devops"
}
