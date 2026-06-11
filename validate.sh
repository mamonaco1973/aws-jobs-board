#!/bin/bash
# ==============================================================================
# Script Name: validate.sh
# ==============================================================================
# Purpose:
#   Validates that the RStudio Application Load Balancer (ALB) is reachable
#   after ECS deployment. Confirms that the ALB endpoint responds with
#   HTTP 200 (OK) and that required Active Directory components are present.
#
# Functional Overview:
#   1. Retrieve DNS names for Windows and Linux AD instances.
#   2. Retrieve the ALB DNS name created during ECS deployment.
#   3. Poll the ALB endpoint until a valid HTTP 200 response is received.
#
# Notes:
#   - Designed for AWS ECS-based RStudio environments.
#   - Exits with nonzero status if validation fails or times out.
# ==============================================================================

MAX_ATTEMPTS=30
SLEEP_SECONDS=10
AWS_DEFAULT_REGION="us-east-1"

# ------------------------------------------------------------------------------
# Step 1: Lookup Active Directory Instances
# ------------------------------------------------------------------------------
# Retrieves hostnames of Windows and Linux AD (Samba gateway) instances.
# Confirms that core AD resources exist before validating ALB reachability.
# ------------------------------------------------------------------------------

# --- Windows AD Instance ------------------------------------------------------
windows_dns=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=windows-ad-admin" \
  --query 'Reservations[].Instances[].PublicDnsName' \
  --output text)

if [ -z "$windows_dns" ]; then
  echo "WARNING: No Windows AD instance found (tag windows-ad-admin)"
else
  echo "NOTE: Windows Instance FQDN: $(echo \"$windows_dns\" | xargs)"
fi

# --- Linux AD (Samba Gateway) Instance ---------------------------------------
linux_dns=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=efs-samba-gateway" \
  --query 'Reservations[].Instances[].PrivateDnsName' \
  --output text)

if [ -z "$linux_dns" ]; then
  echo "WARNING: No EFS Gateway instance found (tag efs-samba-gateway)"
else
  echo "NOTE: EFS Gateway Instance FQDN: $(echo \"$linux_dns\" | xargs)"
fi

# ------------------------------------------------------------------------------
# Step 2: Lookup Application Load Balancer (ALB) DNS Name
# ------------------------------------------------------------------------------
# Retrieves the DNS hostname of the RStudio ALB. This value is used for
# subsequent connectivity tests to verify that the service is online.
# ------------------------------------------------------------------------------
alb_dns=$(aws elbv2 describe-load-balancers \
  --names rstudio-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

if [ -z "$alb_dns" ] || [ "$alb_dns" = "None" ]; then
  echo "ERROR: Failed to retrieve ALB DNS name. Exiting."
  exit 1
fi

# ------------------------------------------------------------------------------
# Step 3: Wait for HTTP 200 Response from Load Balancer
# ------------------------------------------------------------------------------
# Polls the ALB endpoint until an HTTP 200 response is returned. The
# /auth-sign-in path is used as a readiness check for RStudio availability.
# ------------------------------------------------------------------------------
echo "NOTE: Waiting for ALB endpoint (http://${alb_dns}) to return HTTP 200..."

for ((j=1; j<=MAX_ATTEMPTS; j++)); do
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://${alb_dns}/auth-sign-in")

  if [[ "$STATUS_CODE" == "200" ]]; then
    echo "NOTE: RStudio ALB Endpoint: http://$alb_dns"
    echo "NOTE: Validation successful – RStudio is reachable."
    exit 0
  fi

  echo "WARNING: Attempt $j/${MAX_ATTEMPTS}: HTTP ${STATUS_CODE}; retry in \
${SLEEP_SECONDS}s"
  sleep ${SLEEP_SECONDS}
done

# ------------------------------------------------------------------------------
# Timeout and Failure Handling
# ------------------------------------------------------------------------------
# Exits with error if the ALB does not respond with HTTP 200 within the
# defined number of attempts. Used for post-deployment validation checks.
# ------------------------------------------------------------------------------
echo "ERROR: Timed out after ${MAX_ATTEMPTS} attempts waiting for HTTP 200."
exit 1

# ==============================================================================
# End of Script
# ==============================================================================
