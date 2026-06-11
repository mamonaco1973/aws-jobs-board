# ==============================================================================
# Outputs — consumed by 03-ecs via data source tag lookups
# ==============================================================================

output "vpc_id" {
  value = aws_vpc.ecs-vpc.id
}

output "priv_subnet_1_id" {
  value = aws_subnet.priv-subnet-1.id
}

output "priv_subnet_2_id" {
  value = aws_subnet.priv-subnet-2.id
}

output "pub_subnet_1_id" {
  value = aws_subnet.pub-subnet-1.id
}

output "pub_subnet_2_id" {
  value = aws_subnet.pub-subnet-2.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.jobboard.repository_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.jobboard.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.jobboard.cache_nodes[0].address
}
