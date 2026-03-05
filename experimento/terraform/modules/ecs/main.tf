data "aws_region" "current" {}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# Use existing LabRole for AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/${var.project_name}-${var.environment}/inventory"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-inventory-logs"
  }
}

resource "aws_cloudwatch_log_group" "booking" {
  name              = "/ecs/${var.project_name}-${var.environment}/booking"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-booking-logs"
  }
}

# Task Definition - Inventory Service
resource "aws_ecs_task_definition" "inventory" {
  family                   = "${var.project_name}-${var.environment}-inventory"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name  = "inventory"
    image = "${var.inventory_repository_url}:latest"
    
    portMappings = [{
      containerPort = 5001
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@${split(":", var.rds_endpoint)[0]}:5432/${var.inventory_db_name}"
      },
      {
        name  = "FLASK_ENV"
        value = "production"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.inventory.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:5001/api/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "${var.project_name}-${var.environment}-inventory-task"
  }
}

# Task Definition - Booking Service
resource "aws_ecs_task_definition" "booking" {
  family                   = "${var.project_name}-${var.environment}-booking"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name  = "booking"
    image = "${var.booking_repository_url}:latest"
    
    portMappings = [{
      containerPort = 5002
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@${split(":", var.rds_endpoint)[0]}:5432/${var.booking_db_name}"
      },
      {
        name  = "REDIS_HOST"
        value = var.redis_endpoint
      },
      {
        name  = "REDIS_PORT"
        value = "6379"
      },
      {
        name  = "REDIS_DB"
        value = "0"
      },
      {
        name  = "INVENTORY_SERVICE_URL"
        value = "http://${var.alb_dns_name}:5001/api"
      },
      {
        name  = "FLASK_ENV"
        value = "production"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.booking.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:5002/api/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = {
    Name = "${var.project_name}-${var.environment}-booking-task"
  }
}

# Service Discovery removed - use ALB internal DNS instead

# ECS Service - Inventory
resource "aws_ecs_service" "inventory" {
  name            = "${var.project_name}-${var.environment}-inventory"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.inventory_target_group_arn
    container_name   = "inventory"
    container_port   = 5001
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-inventory-service"
  }
}

# ECS Service - Booking
resource "aws_ecs_service" "booking" {
  name            = "${var.project_name}-${var.environment}-booking"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.booking.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.booking_target_group_arn
    container_name   = "booking"
    container_port   = 5002
  }

  depends_on = [aws_ecs_service.inventory]

  tags = {
    Name = "${var.project_name}-${var.environment}-booking-service"
  }
}

# Auto Scaling Target - Inventory
resource "aws_appautoscaling_target" "inventory" {
  max_capacity       = 4
  min_capacity       = var.desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.inventory.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - Inventory (CPU)
resource "aws_appautoscaling_policy" "inventory_cpu" {
  name               = "${var.project_name}-${var.environment}-inventory-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.inventory.resource_id
  scalable_dimension = aws_appautoscaling_target.inventory.scalable_dimension
  service_namespace  = aws_appautoscaling_target.inventory.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Target - Booking
resource "aws_appautoscaling_target" "booking" {
  max_capacity       = 4
  min_capacity       = var.desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.booking.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - Booking (CPU)
resource "aws_appautoscaling_policy" "booking_cpu" {
  name               = "${var.project_name}-${var.environment}-booking-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.booking.resource_id
  scalable_dimension = aws_appautoscaling_target.booking.scalable_dimension
  service_namespace  = aws_appautoscaling_target.booking.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
