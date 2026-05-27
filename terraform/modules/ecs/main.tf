variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU (256 = 0.25 vCPU)"
  type        = string
}

variable "task_memory" {
  description = "Task memory in MB"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "wordpress_image_url" {
  description = "WordPress Docker image URL"
  type        = string
}

variable "wordpress_container_port" {
  description = "WordPress container port"
  type        = number
}

variable "microservice_container_port" {
  description = "Microservice container port"
  type        = number
}

variable "microservice_image_url" {
  description = "Microservice Docker image URL"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "rds_port" {
  description = "RDS port"
  type        = number
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
}

variable "secrets_arn" {
  description = "Secrets Manager ARN"
  type        = string
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
}

variable "autoscaling_target_cpu" {
  description = "Target CPU percentage"
  type        = number
}

variable "autoscaling_target_memory" {
  description = "Target memory percentage"
  type        = number
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "https_listener_arn" {
  description = "HTTPS listener ARN (ensures ALB is ready before ECS services register)"
  type        = string
}

variable "wordpress_subdomain" {
  description = "WordPress subdomain for WP_HOME and WP_SITEURL"
  type        = string
  default     = ""
}

variable "wordpress_domain" {
  description = "WordPress domain name for WP_HOME and WP_SITEURL"
  type        = string
  default     = ""
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "wordpress_service_name" {
  value = aws_ecs_service.wordpress.name
}

output "microservice_service_name" {
  value = aws_ecs_service.microservice.name
}

output "wordpress_target_group_arn" {
  value = aws_lb_target_group.wordpress.arn
}

output "microservice_target_group_arn" {
  value = aws_lb_target_group.microservice.arn
}

resource "null_resource" "alb_https_ready" {
  triggers = {
    https_listener_arn = var.https_listener_arn
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7 # Free tier retention

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled" # Free tier doesn't include Container Insights
  }

  tags = {
    Name = var.ecs_cluster_name
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Task Definition for WordPress
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = var.wordpress_image_url
      essential = true
      portMappings = [
        {
          containerPort = var.wordpress_container_port
          hostPort      = var.wordpress_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = split(":", var.rds_endpoint)[0]
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.rds_database_name
        },
        {
          name  = "WORDPRESS_DB_PORT"
          value = tostring(var.rds_port)
        },
        {
          name  = "WORDPRESS_WP_HOME"
          value = var.wordpress_subdomain != "" && var.wordpress_domain != "" ? "https://${var.wordpress_subdomain}.${var.wordpress_domain}" : "http://localhost"
        },
        {
          name  = "WORDPRESS_WP_SITEURL"
          value = var.wordpress_subdomain != "" && var.wordpress_domain != "" ? "https://${var.wordpress_subdomain}.${var.wordpress_domain}" : "http://localhost"
        }
      ]
      secrets = [
        {
          name      = "WORDPRESS_DB_USER"
          valueFrom = "${var.secrets_arn}:username::"
        },
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.secrets_arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "wordpress"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-wordpress-task"
  }
}

# Task Definition for Microservice
resource "aws_ecs_task_definition" "microservice" {
  family                   = "${var.project_name}-microservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "microservice"
      image     = var.microservice_image_url
      essential = true
      portMappings = [
        {
          containerPort = var.microservice_container_port
          hostPort      = var.microservice_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "microservice"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-microservice-task"
  }
}

resource "aws_ecs_service" "wordpress" {
  name            = "${var.project_name}-wordpress-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "wordpress"
    container_port   = var.wordpress_container_port
  }

  depends_on = [
    aws_ecs_task_definition.wordpress,
    null_resource.alb_https_ready,
  ]

  tags = {
    Name = "${var.project_name}-wordpress-service"
  }
}

resource "aws_ecs_service" "microservice" {
  name            = "${var.project_name}-microservice-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.microservice.arn
    container_name   = "microservice"
    container_port   = var.microservice_container_port
  }

  depends_on = [
    aws_ecs_task_definition.microservice,
    null_resource.alb_https_ready,
  ]

  tags = {
    Name = "${var.project_name}-microservice-service"
  }
}


# Target Group for WordPress
resource "aws_lb_target_group" "wordpress" {
  name        = "${var.project_name}-wordpress-tg"
  port        = var.wordpress_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200,301"
  }

  tags = {
    Name = "${var.project_name}-wordpress-tg"
  }
}

# Target Group for Microservice
resource "aws_lb_target_group" "microservice" {
  name        = "${var.project_name}-microservice-tg"
  port        = var.microservice_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-microservice-tg"
  }
}

resource "aws_appautoscaling_target" "wordpress_target" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.wordpress.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "wordpress_cpu" {
  name               = "${var.project_name}-wordpress-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress_target.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.autoscaling_target_cpu
  }
}

resource "aws_appautoscaling_policy" "wordpress_memory" {
  name               = "${var.project_name}-wordpress-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress_target.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.autoscaling_target_memory
  }
}

resource "aws_appautoscaling_target" "microservice_target" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.microservice.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "microservice_cpu" {
  name               = "${var.project_name}-microservice-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microservice_target.resource_id
  scalable_dimension = aws_appautoscaling_target.microservice_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microservice_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.autoscaling_target_cpu
  }
}

resource "aws_appautoscaling_policy" "microservice_memory" {
  name               = "${var.project_name}-microservice-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microservice_target.resource_id
  scalable_dimension = aws_appautoscaling_target.microservice_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microservice_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.autoscaling_target_memory
  }
}

# Data sources
data "aws_region" "current" {}
