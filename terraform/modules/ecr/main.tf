variable "project_name" {
  description = "Project name"
  type        = string
}

variable "repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "microservice"
}

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}/${var.repository_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.repository_name}-ecr"
  }
}

output "repository_url" {
  value = aws_ecr_repository.main.repository_url
}

