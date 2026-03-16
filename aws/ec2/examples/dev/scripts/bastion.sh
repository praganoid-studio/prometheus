#!/bin/bash
set -euo pipefail

# Update system packages
yum update -y

# Install SSM agent (if not already installed)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install useful utilities
yum install -y \
  jq \
  curl \
  wget \
  unzip \
  htop \
  tmux

# Configure SSH hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
systemctl restart sshd

echo "Bastion host initialization complete - environment: ${environment}"
