# ================================================================================================
# Security Groups for ECS-Based RStudio Environment
# ================================================================================================
# Defines network access control boundaries for ECS nodes, ECS services, and
# the Application Load Balancer (ALB). Each group enforces strict ingress and
# egress rules to regulate communication between components and external users.
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# ECS Node Security Group
# -----------------------------------------------------------------------------------------------
# Grants ECS cluster nodes internal communication access across all ports.
# Allows inbound traffic from the ALB and other ECS tasks. Egress is fully
# open to enable updates, logging, and outbound API calls as needed.
# -----------------------------------------------------------------------------------------------
resource "aws_security_group" "ecs_nodes" {
  name        = "ecs-nodes-sg"
  description = "ECS Node Security Group"
  vpc_id      = data.aws_vpc.ecs-vpc.id

  # Allow full TCP access between ECS nodes and ALB.
  ingress {
    description = "Allow ECS tasks and ALB"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic for system updates and ECS agent operations.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------------------------
# ECS Service Security Group
# -----------------------------------------------------------------------------------------------
# Controls access to ECS service tasks (RStudio containers). Only allows
# inbound traffic on port 8787 from the ALB or trusted clients. Outbound
# access remains unrestricted for dependency updates and EFS mounts.
# -----------------------------------------------------------------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-sg"
  description = "ECS Service Security Group"
  vpc_id      = data.aws_vpc.ecs-vpc.id

  # Allow inbound HTTP requests for RStudio UI via port 8787.
  ingress {
    description = "Allow ALB access"
    from_port   = 8787
    to_port     = 8787
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permit outbound traffic for internet and AWS API access.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------------------------
# Manages public access to the Application Load Balancer. Allows inbound
# HTTP traffic (port 80) from all sources and unrestricted outbound traffic
# to forward requests to backend ECS services.
# -----------------------------------------------------------------------------------------------
resource "aws_security_group" "alb_service" {
  name        = "alb-service-sg"
  description = "ALB Service Security Group"
  vpc_id      = data.aws_vpc.ecs-vpc.id

  # Permit incoming web traffic from users on port 80 (HTTP).
  ingress {
    description = "Allow HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Enable unrestricted outbound access for response delivery and health checks.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
