#!/bin/bash
# ================================================================================================
# Script Name: validate.sh
# ================================================================================================
# Purpose:
#   Validates that the JobBoard ALB is reachable and Rails is responding.
#   Polls the Devise sign-in page until HTTP 200 is received.
#   Fargate tasks need time to start, run migrations, and join the target group.
# ================================================================================================

MAX_ATTEMPTS=40
SLEEP_SECONDS=15
AWS_DEFAULT_REGION="us-east-1"

# ------------------------------------------------------------------------------
# Retrieve ALB DNS Name
# ------------------------------------------------------------------------------
alb_dns=$(aws elbv2 describe-load-balancers \
  --names "jobboard-alb" \
  --query "LoadBalancers[0].DNSName" \
  --output text \
  --region "${AWS_DEFAULT_REGION}" 2>/dev/null || true)

if [ -z "$alb_dns" ] || [ "$alb_dns" = "None" ]; then
  echo "ERROR: Could not find jobboard-alb. Ensure Phase 3 completed successfully."
  exit 1
fi

echo "NOTE: Waiting for http://${alb_dns}/users/sign_in to return HTTP 200..."

# ------------------------------------------------------------------------------
# Poll Until Healthy
# ------------------------------------------------------------------------------
for ((i=1; i<=MAX_ATTEMPTS; i++)); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 \
    "http://${alb_dns}/users/sign_in" 2>/dev/null || echo "000")

  if [ "$STATUS" = "200" ]; then
    echo "NOTE: JobBoard is healthy (HTTP 200)."
    echo "NOTE: URL: http://${alb_dns}"
    exit 0
  fi

  echo "WARNING: Attempt ${i}/${MAX_ATTEMPTS}: HTTP ${STATUS} — retry in ${SLEEP_SECONDS}s"
  sleep "${SLEEP_SECONDS}"
done

echo "ERROR: Timed out after ${MAX_ATTEMPTS} attempts. Check ECS logs in CloudWatch (/ecs/jobboard)."
exit 1

# ================================================================================================
# End of Script
# ================================================================================================
