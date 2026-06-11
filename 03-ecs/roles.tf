# ==============================================================================
# IAM Roles — ECS Task Execution and Runtime
# ==============================================================================

# ------------------------------------------------------------------------------
# Task Execution Role
# Used by ECS agent to pull images, write logs, and read Secrets Manager.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-jobboard"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Allow execution role to read the three application secrets at task start
resource "aws_iam_role_policy" "execution_secrets" {
  name = "jobboard-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        data.aws_secretsmanager_secret.db_url.arn,
        data.aws_secretsmanager_secret.redis_url.arn,
        data.aws_secretsmanager_secret.secret_key_base.arn
      ]
    }]
  })
}

# ------------------------------------------------------------------------------
# Task Runtime Role
# Assumed by the Rails container itself at runtime — needs S3 for ActiveStorage.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_runtime" {
  name = "ecsTaskRuntimeRole-jobboard"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# S3 read/write for ActiveStorage resume uploads
resource "aws_iam_role_policy" "runtime_s3" {
  name = "jobboard-runtime-s3"
  role = aws_iam_role.ecs_task_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }]
  })
}

# ECS Exec — allows `aws ecs execute-command` for debugging
resource "aws_iam_role_policy" "runtime_exec" {
  name = "jobboard-runtime-exec"
  role = aws_iam_role.ecs_task_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}
