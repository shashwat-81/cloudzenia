variable "project_name" {
  description = "Project name"
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

output "secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.rds_credentials.name
}

# RDS credentials for WordPress (no automatic rotation per requirements)
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project_name}/rds/wordpress"
  description             = "WordPress RDS credentials (static, non-rotating)"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-rds-credentials"
  }
}

# Secret version with actual values
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "mysql"
    host     = split(":", var.rds_endpoint)[0] # Extract hostname from endpoint
    port     = var.rds_port
    dbname   = var.db_name
  })
}
