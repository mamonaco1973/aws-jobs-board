# ==============================================================================
# Application Load Balancer
# ==============================================================================
# Public ALB in public subnets routes HTTP (80) to Rails containers on port
# 3000 in private subnets. Health check targets /users/sign_in (Devise).
# ==============================================================================

resource "aws_lb" "jobboard" {
  name               = "jobboard-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    data.aws_subnet.pub-subnet-1.id,
    data.aws_subnet.pub-subnet-2.id
  ]

  tags = { Name = "jobboard-alb" }
}

resource "aws_lb_target_group" "jobboard" {
  name        = "jobboard-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.ecs-vpc.id
  target_type = "ip"

  health_check {
    path                = "/users/sign_in"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "jobboard-tg" }
}

resource "aws_lb_listener" "jobboard" {
  load_balancer_arn = aws_lb.jobboard.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jobboard.arn
  }
}
