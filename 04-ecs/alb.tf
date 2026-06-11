# ================================================================================================
# Application Load Balancer (ALB) for RStudio Service
# ================================================================================================
# Provisions an Application Load Balancer and associated target group to provide
# HTTP access to RStudio Server containers running within ECS. The ALB evenly
# distributes traffic across containers while maintaining session stickiness so
# users remain connected to their assigned RStudio instance.
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------------------------
# Creates an ALB that:
#   - Listens on HTTP (port 80)
#   - Operates within the defined ECS subnets for high availability
#   - Uses a security group to control inbound and outbound traffic
# -----------------------------------------------------------------------------------------------
resource "aws_lb" "rstudio_alb" {
  name               = "rstudio-alb"
  load_balancer_type = "application"

  # Security group allows inbound HTTP from users and outbound to ECS tasks.
  security_groups = [aws_security_group.alb_service.id]

  # Distribute the ALB across multiple subnets for fault tolerance.
  subnets = [
    data.aws_subnet.ecs-subnet-1.id,
    data.aws_subnet.ecs-subnet-2.id
  ]
}

# -----------------------------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------------------------
# Defines the logical group of ECS tasks (containers) that receive traffic from
# the ALB. Configured for:
#   - HTTP protocol on port 8787 (RStudio default)
#   - IP target type for ECS tasks using awsvpc networking
#   - Health checks and cookie-based stickiness for user session persistence
# -----------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "rstudio_tg" {
  name        = "rstudio-tg"
  port        = 8787
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.ecs-vpc.id
  target_type = "ip"

  # Enable session stickiness to maintain persistent user connections.
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400 # 1 day (in seconds)
  }

  # Configure ALB health checks for RStudio login endpoint.
  health_check {
    path                = "/auth-sign-in"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# -----------------------------------------------------------------------------------------------
# ALB Listener
# -----------------------------------------------------------------------------------------------
# Defines how the ALB routes incoming requests. Listens on port 80 (HTTP) and
# forwards all traffic to the RStudio target group.
# -----------------------------------------------------------------------------------------------
resource "aws_lb_listener" "rstudio_listener" {
  load_balancer_arn = aws_lb.rstudio_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rstudio_tg.arn
  }
}
