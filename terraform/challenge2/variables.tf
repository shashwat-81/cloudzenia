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
  description = "DNS suffix (e.g. duckdns.org). FQDN = <subdomain>.<domain_name>"
  type        = string
  default     = "duckdns.org"
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

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Optional EC2 key pair name"
  type        = string
  default     = null
}

variable "certbot_email" {
  description = "Email for Let's Encrypt"
  type        = string
  default     = "admin@example.com"
}

variable "ec2_instance1_subdomain" {
  description = "DuckDNS prefix for instance1 (ec2-instance1-clodzenia.duckdns.org)"
  type        = string
  default     = "ec2-instance1-clodzenia"
}

variable "ec2_docker1_subdomain" {
  description = "DuckDNS prefix for docker1"
  type        = string
  default     = "ec2-docker1-clodzenia"
}

variable "ec2_instance2_subdomain" {
  description = "DuckDNS prefix for instance2"
  type        = string
  default     = "ec2-instance2-clodzenia"
}

variable "ec2_docker2_subdomain" {
  description = "DuckDNS prefix for docker2"
  type        = string
  default     = "ec2-docker2-clodzenia"
}

variable "ec2_alb_instance_subdomain" {
  description = "DuckDNS prefix for ALB instance hostname"
  type        = string
  default     = "ec2-alb-instance-clodzenia"
}

variable "ec2_alb_docker_subdomain" {
  description = "DuckDNS prefix for ALB docker hostname"
  type        = string
  default     = "ec2-alb-docker-clodzenia"
}

