#!/bin/bash
# ================================================================================================
# startup.sh — Container Entrypoint
# ================================================================================================
# Waits for the database, runs migrations and seeds, then starts Puma and Sidekiq.
# Running migrations here makes the container self-healing on redeploy without
# requiring a separate migration task or init container.
# ================================================================================================

set -euo pipefail

echo "NOTE: Starting jobboard container..."

# ------------------------------------------------------------------------------
# Wait for Database
# Retries until Rails can open a connection — RDS may not be immediately
# reachable when ECS starts (cold start, security group propagation, etc.)
# ------------------------------------------------------------------------------
echo "NOTE: Waiting for database connection..."

MAX_ATTEMPTS=30
ATTEMPT=0

until bundle exec rake db:version > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: Database not reachable after ${MAX_ATTEMPTS} attempts. Exiting."
    exit 1
  fi
  echo "NOTE: Attempt ${ATTEMPT}/${MAX_ATTEMPTS} — DB not ready, retrying in 5s..."
  sleep 5
done

echo "NOTE: Database connection established."

# ------------------------------------------------------------------------------
# Migrate and Seed
# rake db:migrate runs all pending migrations.
# rake db:seed uses find_or_create_by! throughout so it is safe to always run.
# ------------------------------------------------------------------------------
echo "NOTE: Running database migrations..."
bundle exec rake db:migrate

echo "NOTE: Seeding demo data if needed..."
bundle exec rake db:seed

# ------------------------------------------------------------------------------
# Start Sidekiq in Background
# Sidekiq processes the :default queue for ApplicationNotificationJob.
# ------------------------------------------------------------------------------
echo "NOTE: Starting Sidekiq..."
bundle exec sidekiq -C config/sidekiq.yml 2>&1 &
SIDEKIQ_PID=$!
echo "NOTE: Sidekiq started (PID ${SIDEKIQ_PID})."

# ------------------------------------------------------------------------------
# Start Puma (foreground — process manager target)
# ------------------------------------------------------------------------------
echo "NOTE: Starting Puma on port 3000..."
exec bundle exec puma -C config/puma.rb

# ================================================================================================
# End of startup.sh
# ================================================================================================
