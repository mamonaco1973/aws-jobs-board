# ==============================================================================
# Secrets Manager — Application Credentials
# ==============================================================================
# Stores DATABASE_URL, REDIS_URL, and SECRET_KEY_BASE as plain-string secrets.
# ECS task definitions inject these at runtime via the secrets: [] block,
# keeping credentials out of image layers and environment variable logs.
# ==============================================================================

# ------------------------------------------------------------------------------
# DB password — alphanumeric only; special chars break connection string URLs
# ------------------------------------------------------------------------------
resource "random_password" "db_password" {
  length  = 24
  special = false
}

# Full connection string — constructed after RDS endpoint is known
resource "aws_secretsmanager_secret" "db_url" {
  name        = "jobboard_database_url"
  description = "Rails DATABASE_URL for jobboard RDS instance"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.jobboard.endpoint}/${var.db_name}"
}

# ------------------------------------------------------------------------------
# Redis URL — constructed from ElastiCache primary endpoint
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "redis_url" {
  name        = "jobboard_redis_url"
  description = "REDIS_URL for Sidekiq and Action Cable"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id     = aws_secretsmanager_secret.redis_url.id
  secret_string = "redis://${aws_elasticache_cluster.jobboard.cache_nodes[0].address}:6379/0"
}

# ------------------------------------------------------------------------------
# SECRET_KEY_BASE — Rails uses this to sign session cookies and tokens
# ------------------------------------------------------------------------------
resource "random_password" "secret_key_base" {
  length  = 128
  special = false
}

resource "aws_secretsmanager_secret" "secret_key_base" {
  name        = "jobboard_secret_key_base"
  description = "Rails SECRET_KEY_BASE for session signing"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "secret_key_base" {
  secret_id     = aws_secretsmanager_secret.secret_key_base.id
  secret_string = random_password.secret_key_base.result
}
