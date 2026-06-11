#!/bin/bash
# ================================================================================================
# Script Name: destroy.sh
# ================================================================================================
# Purpose:
#   Automates the teardown of all AWS infrastructure provisioned for the
#   RStudio environment. This includes ECS services, EC2 instances,
#   Active Directory resources, and related secrets or repositories.
#
# Destruction Phases:
#   1. ECS cluster and networking components
#   2. Domain-joined EC2 server instances
#   3. Active Directory domain controller and secrets
#   4. ECR repository cleanup
#
# Requirements:
#   - AWS CLI v2 and Terraform must be installed
#   - AWS credentials with administrative privileges
#
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# Global Configuration
# -----------------------------------------------------------------------------------------------
# Defines core configuration parameters for teardown operations.
# - AWS_DEFAULT_REGION ensures all deletions target the correct region.
# - set -euo pipefail guarantees the script stops on any error or unset variable.
# -----------------------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
set -euo pipefail

# -----------------------------------------------------------------------------------------------
# Phase 1: Destroy ECS Cluster
# -----------------------------------------------------------------------------------------------
# Removes the ECS cluster, associated task definitions, services, and load
# balancers. Terraform manages dependency order to ensure safe cleanup.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Destroying ECS cluster..."
cd 04-ecs || { echo "ERROR: Directory 04-ecs not found."; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 2: Destroy EC2 Server Instances
# -----------------------------------------------------------------------------------------------
# Deletes EC2-based servers joined to the Active Directory domain. This step
# ensures that all dependent compute resources are removed prior to deleting
# the AD controller itself.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Destroying EC2 server instances..."
cd 02-servers || { echo "ERROR: Directory 02-servers not found."; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 3: Delete AD Secrets and Domain Controller
# -----------------------------------------------------------------------------------------------
# Permanently deletes AWS Secrets Manager entries and removes the Active
# Directory controller. Secrets include user credentials and admin passwords.
# WARNING: This step is irreversible — deleted secrets cannot be recovered.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Deleting AD-related AWS secrets and parameters..."

for secret in \
  akumar_ad_credentials \
  jsmith_ad_credentials \
  edavis_ad_credentials \
  rpatel_ad_credentials \
  rstudio_credentials \
  admin_ad_credentials; do

  aws secretsmanager delete-secret \
    --secret-id "$secret" \
    --force-delete-without-recovery || {
      echo "WARN: Failed to delete secret '$secret'. It may not exist."
    }
done

# -----------------------------------------------------------------------------------------------
# ECR Repository Cleanup
# -----------------------------------------------------------------------------------------------
# Removes the RStudio Docker image repository from Amazon ECR. The --force
# flag ensures all images are deleted prior to repository removal.
# -----------------------------------------------------------------------------------------------
aws ecr delete-repository --repository-name "rstudio" --force || {
  echo "WARN: Failed to delete ECR repository. It may not exist."
}

# -----------------------------------------------------------------------------------------------
# Active Directory Domain Controller Destruction
# -----------------------------------------------------------------------------------------------
# Removes the Active Directory instance that provided authentication services.
# This must occur after dependent EC2 instances have been terminated.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Destroying AD instance..."
cd 01-directory || { echo "ERROR: Directory 01-directory not found."; exit 1; }

terraform init
terraform destroy -auto-approve

cd .. || exit

# -----------------------------------------------------------------------------------------------
# Phase 4: Completion
# -----------------------------------------------------------------------------------------------
# Confirms that all Terraform-managed resources and supporting AWS artifacts
# have been successfully destroyed.
# -----------------------------------------------------------------------------------------------
echo "NOTE: Infrastructure teardown complete."

# ================================================================================================
# End of Script
# ================================================================================================
