variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudzenia"
}

variable "domain_name" {
  description = "Main domain name (e.g., clodzenia.duckdns.org)"
  type        = string
}

variable "wordpress_subdomain" {
  description = "WordPress subdomain"
  type        = string
  default     = "wordpress"
}

variable "microservice_subdomain" {
  description = "Microservice subdomain"
  type        = string
  default     = "microservice"
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID (only needed if you enable ACM DNS validation)"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "wordpress"
}

variable "rds_username" {
  description = "Dedicated WordPress database user (static password, no auto-rotation)"
  type        = string
  default     = "wp_app_user"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class for WordPress"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "cloudzenia-cluster"
}

variable "wordpress_image_url" {
  description = "WordPress Docker image URL"
  type        = string
  default     = "wordpress:latest"
}

variable "wordpress_container_port" {
  description = "WordPress container port"
  type        = number
  default     = 80
}

variable "microservice_container_port" {
  description = "Microservice container port"
  type        = number
  default     = 3000
}

variable "microservice_image_url" {
  description = "Microservice Docker image URL"
  type        = string
  default     = "cloudzenia/microservice:latest"
}

variable "ecs_task_cpu" {
  description = "Task CPU (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 3
}

variable "autoscaling_target_cpu" {
  description = "Target CPU percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "autoscaling_target_memory" {
  description = "Target memory percentage for auto-scaling"
  type        = number
  default     = 80
}

