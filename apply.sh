#!/bin/bash
# ================================================================================================
# Script Name: apply.sh
# ================================================================================================
# Purpose:
#   Deploys the JobBoard Ruby on Rails application end-to-end on AWS.
#
# Deployment Phases:
#   1. Network infrastructure (VPC, RDS, ElastiCache Redis, ECR, S3, Secrets Manager)
#   2. Docker image build and ECR push
#   3. ECS Fargate cluster, ALB, and service deployment
#   4. Post-deployment validation
#
# Requirements:
#   - AWS CLI v2, Terraform, Docker, jq
#   - AWS credentials with administrative permissions
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# Global Configuration
# -----------------------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
set -euo pipefail

# -----------------------------------------------------------------------------------------------
# Environment Pre-Check
# -----------------------------------------------------------------------------------------------
echo "NOTE: Running environment validation..."
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment validation failed. Exiting."
  exit 1
fi

# ================================================================================================
# Phase 1: Network Infrastructure
# ================================================================================================
# Provisions VPC, subnets, RDS PostgreSQL, ElastiCache Redis, ECR repository,
# S3 bucket for uploads, and Secrets Manager entries for all credentials.
# ================================================================================================
echo "NOTE: Building network infrastructure..."
cd 01-network || { echo "ERROR: 01-network not found."; exit 1; }

terraform init
terraform apply -auto-approve

# Capture outputs consumed by the Docker build and ECS phases
export S3_BUCKET=$(terraform output -raw s3_bucket_name)
export ECR_URL=$(terraform output -raw ecr_repository_url)

cd .. || exit

# ================================================================================================
# Phase 2: Build and Push Docker Image
# ================================================================================================
# Builds the Rails application container and pushes it to ECR.
# ================================================================================================
echo "NOTE: Building and pushing Docker image to ECR..."
cd 02-docker/jobboard || { echo "ERROR: 02-docker/jobboard not found."; exit 1; }

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
IMAGE_TAG="${ECR_URL}:latest"

# Authenticate Docker with ECR using temporary STS credentials
aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | \
  docker login --username AWS --password-stdin \
  "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com" || {
    echo "ERROR: Docker ECR authentication failed."
    exit 1
  }

echo "NOTE: Building Docker image..."
docker build -t "${IMAGE_TAG}" . || {
  echo "ERROR: Docker build failed."
  exit 1
}

echo "NOTE: Pushing image to ECR..."
docker push "${IMAGE_TAG}" || {
  echo "ERROR: Docker push failed."
  exit 1
}
echo "NOTE: Image pushed: ${IMAGE_TAG}"

cd ../.. || exit

# ================================================================================================
# Phase 3: ECS Fargate Cluster and Service
# ================================================================================================
# Deploys the ECS Fargate cluster, ALB, task definition, and ECS service.
# Secrets Manager entries from Phase 1 are injected into ECS tasks at runtime.
# ================================================================================================
echo "NOTE: Deploying ECS Fargate cluster and service..."
cd 03-ecs || { echo "ERROR: 03-ecs not found."; exit 1; }

terraform init
terraform apply -auto-approve \
  -var="s3_bucket_name=${S3_BUCKET}"

export ALB_DNS=$(terraform output -raw alb_dns_name)

cd .. || exit

# ================================================================================================
# Phase 4: Validation
# ================================================================================================
echo "NOTE: Running post-deployment validation..."
./validate.sh

echo ""
echo "NOTE: Deployment complete."
echo "NOTE: JobBoard URL:           http://${ALB_DNS}"
echo "NOTE: Candidate login:        candidate1@example.com / password123"
echo "NOTE: Employer login:         employer1@example.com  / password123"

# ================================================================================================
# End of Script
# ================================================================================================
