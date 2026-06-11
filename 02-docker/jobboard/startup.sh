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

until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" \
      > /dev/null 2>&1; do
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
# db:prepare = db:create (if missing) + db:migrate
# Seeds run only when the jobs table is empty to avoid duplicate demo data.
# ------------------------------------------------------------------------------
echo "NOTE: Running database migrations..."
bundle exec rails db:prepare

echo "NOTE: Seeding demo data if needed..."
bundle exec rails runner "
  if Job.count.zero?
    load Rails.root.join('db/seeds.rb')
  else
    puts 'NOTE: Data already present, skipping seeds.'
  end
"

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
