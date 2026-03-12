aws_region     = "us-east-1"
name_prefix    = "myapp-prod"
environment    = "production"
vpc_cidr_block = "10.0.0.0/16"

bastion_ami_id = "ami-0123456789abcdef0"
app_ami_id     = "ami-0123456789abcdef0"
worker_ami_id  = "ami-0123456789abcdef0"

ssh_allowed_cidrs = ["203.0.113.0/32"]

app_iam_policy_arns    = []
worker_iam_policy_arns = []
app_target_group_arns  = []

tags = {
  Project = "myapp"
  Owner   = "devops"
}
