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

variable "challenge2_state_path" {
  description = "Path to Challenge 2 terraform.tfstate (local backend)"
  type        = string
  default     = "../challenge2/terraform.tfstate"
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group for NGINX access logs"
  type        = string
  default     = "/ec2/nginx/access"
}
