# ==============================================================================
# Outputs
# ==============================================================================

output "alb_dns_name" {
  description = "Public URL for the jobboard application"
  value       = aws_lb.jobboard.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.jobboard.name
}

output "ecs_service_name" {
  value = aws_ecs_service.jobboard.name
}
