#!/bin/bash
set -euo pipefail

# Update system packages
yum update -y

# Install SSM agent (if not already installed)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Install application dependencies
yum install -y \
  jq \
  curl \
  wget \
  unzip

# Configure CloudWatch agent (basic memory and disk metrics)
cat <<'CWCONFIG' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "EC2/${environment}",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "Application server initialization complete - environment: ${environment}, region: ${region}"
