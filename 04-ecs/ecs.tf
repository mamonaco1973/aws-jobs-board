# ================================================================================================
# ECS Cluster and EC2 Node Infrastructure for RStudio Service
# ================================================================================================
# Provisions a complete ECS environment using EC2 launch type to host RStudio
# Server containers. Includes cluster creation, Auto Scaling Group (ASG) for
# ECS nodes, capacity provider configuration, task definitions, service setup,
# and CloudWatch logging.
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# ECS Cluster (EC2 Launch Type)
# -----------------------------------------------------------------------------------------------
# Defines the ECS cluster that manages RStudio Server tasks on EC2 instances.
# Enables Container Insights for performance and log visibility.
# -----------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "rstudio_cluster" {
  name = "rstudio"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# -----------------------------------------------------------------------------------------------
# ECS Node Launch Template
# -----------------------------------------------------------------------------------------------
# Defines the EC2 instance template used by the ECS Auto Scaling Group. Each
# node joins the ECS cluster automatically using userdata defined in a shell
# script. Tags ensure proper identification and cost allocation.
# -----------------------------------------------------------------------------------------------
resource "aws_launch_template" "ecs_lt" {
  name          = "rstudio-ecs-lt"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.medium"

  # Attach IAM instance profile with ECS and Secrets Manager permissions.
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Security group allows ECS agent and internal communication.
  vpc_security_group_ids = [aws_security_group.ecs_nodes.id]

  # Bootstrap ECS node to join the specified cluster on startup.
  user_data = base64encode(templatefile("${path.module}/scripts/ecs_userdata.sh", {
    cluster_name = aws_ecs_cluster.rstudio_cluster.name
  }))

  # Apply tags directly to EC2 instances at launch.
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name             = "rstudio-ecs-node"
      Cluster          = aws_ecs_cluster.rstudio_cluster.name
      Environment      = "dev"
      AmazonECSManaged = "true"
    }
  }

  # Optional: Tag the launch template object itself.
  tags = { Name = "rstudio-ecs-lt" }
}

# -----------------------------------------------------------------------------------------------
# ECS Node Auto Scaling Group
# -----------------------------------------------------------------------------------------------
# Creates an Auto Scaling Group (ASG) that maintains the ECS cluster’s EC2
# instances. Protects instances from scale-in termination and ensures capacity
# across multiple subnets.
# -----------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_asg" {
  name             = "rstudio-ecs-asg"
  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  # Deploy nodes across private subnets for high availability.
  vpc_zone_identifier = [
    data.aws_subnet.ecs-private-subnet-1.id,
    data.aws_subnet.ecs-private-subnet-2.id
  ]

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  # Ensure ECS recognizes these instances as managed.
  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  # Prevent ECS nodes from being terminated during scaling events.
  protect_from_scale_in = true
}

# -----------------------------------------------------------------------------------------------
# ECS Capacity Provider
# -----------------------------------------------------------------------------------------------
# Links the Auto Scaling Group to ECS with managed scaling enabled. Ensures
# ECS automatically adjusts EC2 instance count based on task demand. Used in
# combination with a placement constraint to guarantee one task per node.
# -----------------------------------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "rstudio_cp" {
  name = "rstudio-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "ENABLED"

    # Enable ECS to automatically manage ASG scaling based on service load.
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
      instance_warmup_period    = 60
    }
  }

  tags = {
    Name = "rstudio-capacity-provider"
  }
}

# -----------------------------------------------------------------------------------------------
# ECS Cluster Capacity Provider Association
# -----------------------------------------------------------------------------------------------
# Associates the ECS Capacity Provider with the ECS cluster and defines it as
# the default provider strategy for service deployments.
# -----------------------------------------------------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "rstudio_assoc" {
  cluster_name       = aws_ecs_cluster.rstudio_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.rstudio_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.rstudio_cp.name
    weight            = 1
  }
}

# -----------------------------------------------------------------------------------------------
# ECS Task Definition (EC2 Launch Type)
# -----------------------------------------------------------------------------------------------
# Describes the RStudio container configuration including CPU/memory, image,
# environment variables, EFS mounts, and logging. Defines required IAM roles
# and enables persistent storage.
# -----------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "rstudio_task" {
  family                   = "rstudio-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "1024"

  # Task execution and runtime roles for ECS agent and application access.
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_runtime.arn

  # Define container specifications and runtime configuration.
  container_definitions = jsonencode([
    {
      name      = "rstudio"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/rstudio:rstudio-server-rc1"
      essential = true

      environment = [
        { name = "ADMIN_SECRET", value = "admin_ad_credentials" },
        { name = "DOMAIN_FQDN", value = var.dns_zone },
        { name = "REGION", value = data.aws_region.current.id }
      ]

      portMappings = [
        { containerPort = 8787, hostPort = 8787, protocol = "tcp" }
      ]

      mountPoints = [
        { sourceVolume = "efs-root", containerPath = "/efs" },
        { sourceVolume = "efs-home", containerPath = "/home" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/rstudio"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "rstudio"
        }
      }
    }
  ])

  # Define EFS-backed volumes for persistent data and user directories.
  volume {
    name = "efs-root"
    efs_volume_configuration {
      file_system_id     = data.aws_efs_file_system.efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  volume {
    name = "efs-home"
    efs_volume_configuration {
      file_system_id     = data.aws_efs_file_system.efs.id
      root_directory     = "/home"
      transit_encryption = "ENABLED"
    }
  }
}

# -----------------------------------------------------------------------------------------------
# ECS Service (EC2 Launch Type)
# -----------------------------------------------------------------------------------------------
# Deploys the RStudio ECS task as a service that maintains the desired number
# of containers. Integrates with the ALB for external access via port 8787 and
# allows remote debugging via ECS Exec.
# -----------------------------------------------------------------------------------------------
resource "aws_ecs_service" "rstudio_service" {
  name                   = "rstudio-service"
  cluster                = aws_ecs_cluster.rstudio_cluster.id
  task_definition        = aws_ecs_task_definition.rstudio_task.arn
  desired_count          = 2
  launch_type            = "EC2"
  enable_execute_command = true

  network_configuration {
    subnets = [
      data.aws_subnet.ecs-private-subnet-1.id,
      data.aws_subnet.ecs-private-subnet-2.id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service.id]
  }

  # Attach to ALB target group for HTTP traffic routing.
  load_balancer {
    target_group_arn = aws_lb_target_group.rstudio_tg.arn
    container_name   = "rstudio"
    container_port   = 8787
  }

  depends_on = [aws_lb_listener.rstudio_listener]
}

# -----------------------------------------------------------------------------------------------
# CloudWatch Log Group for ECS RStudio Tasks
# -----------------------------------------------------------------------------------------------
# Creates a CloudWatch log group for ECS container logs, enabling centralized
# monitoring and troubleshooting. Retains logs for 7 days.
# -----------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "rstudio" {
  name              = "/ecs/rstudio"
  retention_in_days = 7
  tags = {
    Name        = "rstudio-log-group"
    Environment = "dev"
  }
}

# ================================================================================================
# ECS Service Auto Scaling (Scale-Out Only)
# ================================================================================================
# Automatically increases the number of ECS tasks when average CPU utilization
# exceeds 60%. Scale-in behavior is disabled to ensure that RStudio workloads
# remain stable and do not terminate under transient load drops.
#
# This works in combination with the ECS Capacity Provider and the EC2 Auto
# Scaling Group (ASG). When new tasks exceed current node capacity, the ASG
# automatically provisions new instances to host them.
# ================================================================================================

# -----------------------------------------------------------------------------------------------
# Application Auto Scaling Target
# -----------------------------------------------------------------------------------------------
# Registers the ECS Service as a scalable target in Application Auto Scaling.
# Sets allowable bounds for desired task count (2 minimum, 6 maximum).
# -----------------------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "rstudio_service_scaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.rstudio_cluster.name}/${aws_ecs_service.rstudio_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 6
}

# -----------------------------------------------------------------------------------------------
# Application Auto Scaling Policy
# -----------------------------------------------------------------------------------------------
# Defines a target-tracking policy based on average ECS CPU utilization.
# Only scale-out events are permitted; scale-in is explicitly disabled.
# -----------------------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "rstudio_service_scaling_policy" {
  name               = "rstudio-service-scaleout"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.rstudio_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.rstudio_service_scaling_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0              # Trigger threshold for scale-out
    disable_scale_in   = true              # Prevent task reduction
    scale_out_cooldown = 120               # Seconds to wait before next scale-out
  }
}
