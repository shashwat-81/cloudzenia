variable "project_name" {
  description = "Project name"
  type        = string
}

variable "repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "microservice"
}

variable "use_existing_repository" {
  description = "Set true if the ECR repo already exists in AWS (e.g. after a prior apply/destroy)"
  type        = bool
  default     = false
}

locals {
  repository_full_name = "${var.project_name}/${var.repository_name}"
}

data "aws_ecr_repository" "existing" {
  count = var.use_existing_repository ? 1 : 0
  name  = local.repository_full_name
}

resource "aws_ecr_repository" "main" {
  count = var.use_existing_repository ? 0 : 1

  name                 = local.repository_full_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-${var.repository_name}-ecr"
  }
}

output "repository_url" {
  value = var.use_existing_repository ? data.aws_ecr_repository.existing[0].repository_url : aws_ecr_repository.main[0].repository_url
}

output "repository_arn" {
  value = var.use_existing_repository ? data.aws_ecr_repository.existing[0].arn : aws_ecr_repository.main[0].arn
}
