# ==============================================================================
# Data Sources — look up resources created by 01-network by tag/name
# ==============================================================================

data "aws_vpc" "ecs-vpc" {
  filter {
    name   = "tag:Name"
    values = ["ecs-vpc"]
  }
}

data "aws_subnet" "priv-subnet-1" {
  filter {
    name   = "tag:Name"
    values = ["priv-subnet-1"]
  }
}

data "aws_subnet" "priv-subnet-2" {
  filter {
    name   = "tag:Name"
    values = ["priv-subnet-2"]
  }
}

data "aws_subnet" "pub-subnet-1" {
  filter {
    name   = "tag:Name"
    values = ["pub-subnet-1"]
  }
}

data "aws_subnet" "pub-subnet-2" {
  filter {
    name   = "tag:Name"
    values = ["pub-subnet-2"]
  }
}

data "aws_ecr_repository" "jobboard" {
  name = "jobboard"
}

# Secrets created in 01-network, injected into ECS task at runtime
data "aws_secretsmanager_secret" "db_url" {
  name = "jobboard_database_url"
}

data "aws_secretsmanager_secret" "redis_url" {
  name = "jobboard_redis_url"
}

data "aws_secretsmanager_secret" "secret_key_base" {
  name = "jobboard_secret_key_base"
}
