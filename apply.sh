#!/bin/bash
# ================================================================================================
# Script Name: apply.sh
# ================================================================================================
# Purpose:
#   Automates deployment of a full AWS-hosted RStudio environment using
#   Terraform and Docker. The process is organized into multiple phases that
#   provision infrastructure, build Docker images, and deploy ECS workloads.
#
# Deployment Phases:
#   1. Active Directory domain controller (authentication backbone)
#   2. Domain-joined EC2 management servers
#   3. RStudio Docker image build and ECR push
#   4. ECS cluster deployment for RStudio containers
#   5. Post-deployment validation and checks
#
# Requirements:
#   - AWS CLI v2, Terraform, Docker, jq
#   - AWS credentials with administrative permissions
#
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# Global Configuration
# -----------------------------------------------------------------------------------------------
# Configure environment-wide defaults and ensure strict error handling.
# - AWS_DEFAULT_REGION defines the target AWS region.
# - set -euo pipefail ensures immediate failure on errors or unset variables.
# -----------------------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
set -euo pipefail

# -----------------------------------------------------------------------------------------------
# Environment Pre-Check
# -----------------------------------------------------------------------------------------------
# Validates that prerequisites are installed and the environment is configured
# properly. The `check_env.sh` script verifies the presence of required tools
# and credentials before proceeding.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Running environment validation..."
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment validation failed. Exiting."
  exit 1
fi

# -----------------------------------------------------------------------------------------------
# Phase 1: Build Active Directory Domain Controller
# -----------------------------------------------------------------------------------------------
# Deploys the Active Directory domain controller via Terraform. This instance
# provides authentication services required by downstream EC2 and ECS nodes.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Building Active Directory instance..."
cd 01-directory || { echo "ERROR: 01-directory not found."; exit 1; }

terraform init
terraform apply -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 2: Build Dependent EC2 Servers
# -----------------------------------------------------------------------------------------------
# Provisions domain-joined EC2 instances that serve as auxiliary systems or
# management servers. These depend on a functioning AD domain from Phase 1.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Building EC2 server instances..."
cd 02-servers || { echo "ERROR: 02-servers not found."; exit 1; }

terraform init
terraform apply -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 3: Build RStudio Docker Image and Push to ECR
# -----------------------------------------------------------------------------------------------
# Builds the RStudio Server container image locally and uploads it to Amazon
# Elastic Container Registry (ECR). This image is later deployed via ECS.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Building RStudio Docker image and pushing to ECR..."
cd 03-docker/rstudio || { echo "ERROR: rstudio directory missing."; exit 1; }

# Retrieve AWS Account ID for ECR repository reference.
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "ERROR: Failed to retrieve AWS Account ID. Exiting."
  exit 1
fi

# Authenticate Docker with ECR using temporary credentials.
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
docker login --username AWS --password-stdin \
"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com" || {
  echo "ERROR: Docker authentication failed. Exiting."
  exit 1
}

# Retrieve RStudio credentials from AWS Secrets Manager.
RSTUDIO_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id rstudio_credentials \
  --query 'SecretString' \
  --output text | jq -r '.password')

if [ -z "$RSTUDIO_PASSWORD" ] || [ "$RSTUDIO_PASSWORD" = "null" ]; then
  echo "ERROR: Failed to retrieve RStudio password. Exiting."
  exit 1
fi

# -----------------------------------------------------------------------------------------------
# Build and Push RStudio Docker Image
# -----------------------------------------------------------------------------------------------
# Checks if the image already exists in ECR. If not found, it builds and pushes
# the image. Prevents unnecessary rebuilds when image is already available.
# -----------------------------------------------------------------------------------------------
IMAGE_TAG="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/rstudio:rstudio-server-rc1"

echo "NOTE: Checking if image already exists in ECR..."
if aws ecr describe-images \
    --repository-name rstudio \
    --image-ids imageTag="rstudio-server-rc1" \
    --region "${AWS_DEFAULT_REGION}" >/dev/null 2>&1; then
  echo "NOTE: Image already exists in ECR: ${IMAGE_TAG}"
else
  echo "WARNING: Image not found in ECR. Building and pushing..."

  docker build \
    --build-arg RSTUDIO_PASSWORD="${RSTUDIO_PASSWORD}" \
    -t "${IMAGE_TAG}" . || {
      echo "ERROR: Docker build failed. Exiting."
      exit 1
    }

  docker push "${IMAGE_TAG}" || {
    echo "ERROR: Docker push failed. Exiting."
    exit 1
  }

  echo "NOTE: Image successfully built and pushed to ECR: ${IMAGE_TAG}"
fi

cd ../.. || exit

# -----------------------------------------------------------------------------------------------
# Phase 4: Build ECS Cluster
# -----------------------------------------------------------------------------------------------
# Deploys the ECS cluster infrastructure using Terraform. This includes node
# groups, capacity providers, and service definitions for RStudio containers.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Building ECS cluster..."
cd 04-ecs || { echo "ERROR: 04-ecs directory missing."; exit 1; }

terraform init
terraform apply -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 5: Build Validation
# -----------------------------------------------------------------------------------------------
# Executes validation checks to confirm that the environment is deployed
# correctly, domain joins succeed, and services are reachable.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Running build validation..."
./validate.sh  # Uncomment once validation script is implemented

# ================================================================================================
# End of Script
# ================================================================================================
