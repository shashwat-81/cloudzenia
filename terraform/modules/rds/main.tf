variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.endpoint
}

output "rds_address" {
  value = aws_db_instance.wordpress.address
}

output "rds_port" {
  value = aws_db_instance.wordpress.port
}

output "rds_database_name" {
  value = aws_db_instance.wordpress.db_name
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "wordpress" {
  identifier        = "${var.project_name}-wordpress-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  storage_encrypted = false # Free tier doesn't support encryption

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  # Automated backups (free tier limitation: retention must be <= 1 day)
  backup_retention_period  = 1
  backup_window            = "03:00-04:00"
  maintenance_window       = "mon:04:00-mon:05:00"
  delete_automated_backups = false

  # Private subnets only
  publicly_accessible = false

  # Disable automatic minor version upgrades to keep costs low
  auto_minor_version_upgrade = true

  # Enable deletion protection in production
  skip_final_snapshot   = true # For testing - remove in production
  copy_tags_to_snapshot = true

  tags = {
    Name = "${var.project_name}-wordpress-db"
  }
}
