# ================================================================================================
# IAM Roles and Policies for ECS-Based RStudio Service
# ================================================================================================
# Defines IAM roles, instance profiles, and policies required for ECS tasks,
# EC2 nodes, and CloudWatch integration. These roles provide secure access to
# AWS services such as Secrets Manager, SSM, and CloudWatch Logs.
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------------------------
# Grants the ECS agent permissions to pull container images, write logs, and
# interact with ECS control plane services. This role is assumed by ECS tasks
# during startup to execute container operations.
# -----------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-rstudio"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------------
# ECS Task Execution Role Attachments
# -----------------------------------------------------------------------------------------------
# Attach AWS-managed policies that allow ECS tasks to:
#   - Use ECS service-linked roles for execution.
#   - Read parameters from SSM.
#   - Send logs to CloudWatch.
# -----------------------------------------------------------------------------------------------

# ECS default execution permissions (ECR, CloudWatch Logs, etc.)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Read-only access to AWS Systems Manager parameters.
resource "aws_iam_role_policy_attachment" "ecs_task_ssm_readonly" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Enable ECS tasks to write application logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_logs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# -----------------------------------------------------------------------------------------------
# ECS Task Runtime Role
# -----------------------------------------------------------------------------------------------
# Provides runtime permissions for the RStudio application running inside ECS
# containers. This role is separate from the execution role and grants access
# to domain secrets or other sensitive data at runtime.
# -----------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_runtime" {
  name = "ecsTaskRuntimeRole-rstudio"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------------
# ECS Instance Role (EC2 Launch Type)
# -----------------------------------------------------------------------------------------------
# Defines the IAM role assumed by ECS EC2 instances. Grants them permissions
# to register with ECS, communicate with the ECS control plane, and use SSM
# for secure remote management via AWS Systems Manager.
# -----------------------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_instance" {
  name = "ecsInstanceRole-rstudio"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach standard ECS permissions for EC2-based ECS agents.
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach SSM management permissions for remote access and automation.
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------------------------
# ECS Instance Profile
# -----------------------------------------------------------------------------------------------
# Creates an instance profile to attach the ECS Instance Role to EC2 nodes.
# Required for EC2 instances to assume their designated IAM role at launch.
# -----------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile-rstudio"
  role = aws_iam_role.ecs_instance.name
}

# -----------------------------------------------------------------------------------------------
# Custom Policy: Secrets Manager Access for RStudio Tasks
# -----------------------------------------------------------------------------------------------
# Grants ECS tasks permission to read specific application secrets from AWS
# Secrets Manager. This policy is attached to the runtime role for secure
# retrieval of AD credentials and domain configuration.
# -----------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "rstudio_task_secrets_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rstudio_task_secrets" {
  name   = "rstudio-task-secrets-policy"
  policy = data.aws_iam_policy_document.rstudio_task_secrets_policy.json
}

resource "aws_iam_role_policy_attachment" "rstudio_task_secrets_attach" {
  role       = aws_iam_role.ecs_task_runtime.name
  policy_arn = aws_iam_policy.rstudio_task_secrets.arn
}
