variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "project_name" {
  description = "Project name"
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

variable "vpc_cidr" {
  description = "VPC CIDR for scoped ECS egress to RDS"
  type        = string
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

# ALB: public HTTP/HTTPS only
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB - allows HTTP/HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere (redirects to HTTPS)"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ECS: ingress from ALB only; egress to RDS and AWS APIs
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks - allows traffic from ALB and RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.wordpress_container_port
    to_port         = var.wordpress_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB to WordPress"
  }

  ingress {
    from_port       = var.microservice_container_port
    to_port         = var.microservice_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB to Microservice"
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL to RDS in VPC"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for ECR, Secrets Manager, CloudWatch Logs"
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# RDS: MySQL from ECS only
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS - allows traffic from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
    description     = "Allow MySQL traffic from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
