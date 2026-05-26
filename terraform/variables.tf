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

# VPC Variables
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

# RDS Variables
variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "wordpress"
}

variable "route53_zone_id" {
  description = "Optional Route53 zone ID for ACM validation and ALB alias records"
  type        = string
  default     = ""
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
  description = "RDS instance class for WordPress (MySQL 8; db.t3.small+ recommended for production)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB (free tier: 20GB)"
  type        = number
  default     = 20
}

# ECS Variables
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

variable "ecs_task_cpu" {
  description = "ECS task CPU (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

# Auto-scaling variables
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

# -------------------------------
# Challenge 2: EC2 + NGINX + Docker + Let's Encrypt
# -------------------------------

variable "ec2_instance_type" {
  description = "EC2 instance type for the challenge 2 servers"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Optional EC2 key pair for SSH (not required if you rely only on user_data)"
  type        = string
  default     = null
}

variable "certbot_email" {
  description = "Email for Let's Encrypt registration"
  type        = string
  default     = "admin@example.com"
}

variable "ec2_instance1_subdomain" {
  description = "ec2-instance1 subdomain"
  type        = string
  default     = "ec2-instance1"
}

variable "ec2_docker1_subdomain" {
  description = "ec2-docker1 subdomain"
  type        = string
  default     = "ec2-docker1"
}

variable "ec2_instance2_subdomain" {
  description = "ec2-instance2 subdomain"
  type        = string
  default     = "ec2-instance2"
}

variable "ec2_docker2_subdomain" {
  description = "ec2-docker2 subdomain"
  type        = string
  default     = "ec2-docker2"
}

variable "ec2_alb_docker_subdomain" {
  description = "ec2-alb-docker subdomain"
  type        = string
  default     = "ec2-alb-docker"
}

variable "ec2_alb_instance_subdomain" {
  description = "ec2-alb-instance subdomain"
  type        = string
  default     = "ec2-alb-instance"
}
