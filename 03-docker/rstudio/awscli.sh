#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------------
# Install AWS CLI v2
# ---------------------------------------------------------------------------------
# Provides access to AWS APIs (e.g., Secrets Manager, S3)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -f -r awscliv2.zip aws
