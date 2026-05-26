output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "wordpress_url" {
  description = "WordPress HTTPS URL (may show warning if cert is self-signed)"
  value       = "https://${var.wordpress_subdomain}.${var.domain_name}"
}

output "microservice_url" {
  description = "Microservice HTTPS URL (may show warning if cert is self-signed)"
  value       = "https://${var.microservice_subdomain}.${var.domain_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "microservice_ecr_repo_url" {
  description = "ECR repository URL for microservice images"
  value       = module.ecr.repository_url
}

