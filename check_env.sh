#!/bin/bash
# ================================================================================================
# check_env.sh
# ================================================================================================
# Validates required CLI tools and AWS credentials before apply.sh proceeds.
# ================================================================================================

set -u

echo "NOTE: Validating that required commands are found in your PATH."

commands=("aws" "terraform" "docker" "jq")
all_found=true

for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

if [ "$all_found" != true ]; then
  echo "ERROR: One or more required commands are missing."
  exit 1
fi

echo "NOTE: All required commands are available."

echo "NOTE: Checking AWS CLI connection."
if ! aws sts get-caller-identity --query "Account" --output text > /dev/null 2>&1; then
  echo "ERROR: Failed to connect to AWS. Check credentials or environment variables."
  exit 1
fi
echo "NOTE: Successfully logged into AWS."
