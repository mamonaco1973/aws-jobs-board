#!/bin/bash
# ================================================================================================
# Script Name: destroy.sh
# ================================================================================================
# Purpose:
#   Tears down all AWS infrastructure provisioned by apply.sh.
#   Destroys resources in reverse dependency order.
#
# Destruction Phases:
#   1. ECS Fargate service and ALB
#   2. ECR repository (force-delete all images)
#   3. Secrets Manager entries
#   4. Network infrastructure (VPC, RDS, ElastiCache Redis, S3)
# ================================================================================================

export AWS_DEFAULT_REGION="us-east-1"
set -euo pipefail

# ================================================================================================
# Phase 1: Destroy ECS Cluster and ALB
# ================================================================================================
echo "NOTE: Destroying ECS cluster and ALB..."
cd 03-ecs || { echo "ERROR: Directory 03-ecs not found."; exit 1; }

# Resolve the S3 bucket name to satisfy the Terraform variable during destroy
S3_BUCKET=$(aws s3api list-buckets \
  --query "Buckets[?starts_with(Name,'jobboard-uploads')].Name | [0]" \
  --output text 2>/dev/null || echo "jobboard-uploads-placeholder")

terraform init
terraform destroy -auto-approve -var="s3_bucket_name=${S3_BUCKET}" || true

cd .. || exit

# ================================================================================================
# Phase 2: Delete ECR Images and Repository
# Terraform created the ECR repo in 01-network; delete images manually first
# since terraform destroy in 01-network would fail on a non-empty repository.
# ================================================================================================
echo "NOTE: Deleting ECR repository..."
aws ecr delete-repository \
  --repository-name "jobboard" \
  --force \
  --region "${AWS_DEFAULT_REGION}" 2>/dev/null || \
  echo "WARN: ECR repository not found or already deleted."

# ================================================================================================
# Phase 3: Delete Secrets Manager Entries
# Terraform marks secrets for deletion with a recovery window; --force-delete
# bypasses the 7-30 day window so re-deploys can reuse the same secret names.
# ================================================================================================
echo "NOTE: Deleting Secrets Manager entries..."

for secret in \
  jobboard_database_url \
  jobboard_redis_url \
  jobboard_secret_key_base; do

  aws secretsmanager delete-secret \
    --secret-id "$secret" \
    --force-delete-without-recovery \
    --region "${AWS_DEFAULT_REGION}" 2>/dev/null || \
    echo "WARN: Secret '${secret}' not found or already deleted."
done

# ================================================================================================
# Phase 4: Destroy Network Infrastructure
# ================================================================================================
echo "NOTE: Destroying network infrastructure..."
cd 01-network || { echo "ERROR: Directory 01-network not found."; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit

echo "NOTE: Infrastructure teardown complete."

# ================================================================================================
# End of Script
# ================================================================================================
