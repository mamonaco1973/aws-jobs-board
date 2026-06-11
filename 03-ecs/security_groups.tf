# ==============================================================================
# Security Groups — ALB and ECS Service
# ==============================================================================

# ------------------------------------------------------------------------------
# ALB Security Group
# Allows public HTTP (80) inbound; ECS tasks only accept traffic from ALB.
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "jobboard-alb-sg"
  description = "ALB inbound HTTP"
  vpc_id      = data.aws_vpc.ecs-vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jobboard-alb-sg" }
}

# ------------------------------------------------------------------------------
# ECS Service Security Group
# Rails runs on port 3000; only ALB is allowed to initiate connections.
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "jobboard-ecs-sg"
  description = "ECS tasks — allow from ALB only"
  vpc_id      = data.aws_vpc.ecs-vpc.id

  ingress {
    description     = "Rails from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jobboard-ecs-sg" }
}
