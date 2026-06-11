# ==============================================================================
# ECS Fargate Cluster, Task Definition, and Service
# ==============================================================================
# Fargate eliminates EC2 node management vs. the EC2 launch type used in
# rstudio-ecs. No ASG, launch template, or capacity provider needed.
# ==============================================================================

resource "aws_ecs_cluster" "jobboard" {
  name = "jobboard"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "jobboard-cluster" }
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "jobboard" {
  name              = "/ecs/jobboard"
  retention_in_days = 7

  tags = { Name = "jobboard-logs" }
}

# ------------------------------------------------------------------------------
# Task Definition
# Secrets injected from Secrets Manager — never in image layers or env logs.
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "jobboard" {
  family                   = "jobboard-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_runtime.arn

  container_definitions = jsonencode([
    {
      name      = "jobboard"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/jobboard:${var.image_tag}"
      essential = true

      environment = [
        { name = "RAILS_ENV",                value = "production" },
        { name = "RAILS_LOG_TO_STDOUT",      value = "true" },
        { name = "RAILS_SERVE_STATIC_FILES", value = "true" },
        { name = "AWS_REGION",               value = data.aws_region.current.id },
        { name = "S3_BUCKET",                value = var.s3_bucket_name }
      ]

      # Secrets Manager injects these at task start before the container runs
      secrets = [
        { name = "DATABASE_URL",    valueFrom = data.aws_secretsmanager_secret.db_url.arn },
        { name = "REDIS_URL",       valueFrom = data.aws_secretsmanager_secret.redis_url.arn },
        { name = "SECRET_KEY_BASE", valueFrom = data.aws_secretsmanager_secret.secret_key_base.arn }
      ]

      portMappings = [
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/jobboard"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "jobboard"
        }
      }
    }
  ])
}

# ------------------------------------------------------------------------------
# ECS Service — Fargate, 1 desired task for demo (scale up as needed)
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "jobboard" {
  name                   = "jobboard-service"
  cluster                = aws_ecs_cluster.jobboard.id
  task_definition        = aws_ecs_task_definition.jobboard.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = [
      data.aws_subnet.priv-subnet-1.id,
      data.aws_subnet.priv-subnet-2.id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.jobboard.arn
    container_name   = "jobboard"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.jobboard]
}
