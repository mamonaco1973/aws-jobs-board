# ==============================================================================
# ElastiCache Redis — Sidekiq Queue Backend
# ==============================================================================
# Single-node Redis cluster (no cluster mode) — sufficient for Sidekiq
# background jobs and Action Cable in a demo environment.
# ==============================================================================

resource "aws_elasticache_subnet_group" "jobboard" {
  name       = "jobboard-redis-subnet-group"
  subnet_ids = [aws_subnet.priv-subnet-1.id, aws_subnet.priv-subnet-2.id]

  tags = { Name = "jobboard-redis-subnet-group" }
}

# Allow Redis from within the VPC only
resource "aws_security_group" "redis" {
  name        = "jobboard-redis-sg"
  description = "Allow Redis from VPC"
  vpc_id      = aws_vpc.ecs-vpc.id

  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ecs-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jobboard-redis-sg" }
}

resource "aws_elasticache_cluster" "jobboard" {
  cluster_id           = "jobboard-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.jobboard.name
  security_group_ids = [aws_security_group.redis.id]

  tags = { Name = "jobboard-redis" }
}
