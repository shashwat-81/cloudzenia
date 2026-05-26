output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway IPs"
  value       = module.vpc.nat_gateway_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_address" {
  description = "RDS address"
  value       = module.rds.rds_address
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "wordpress_service_name" {
  description = "WordPress ECS service name"
  value       = module.ecs.wordpress_service_name
}

output "microservice_service_name" {
  description = "Microservice ECS service name"
  value       = module.ecs.microservice_service_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = module.alb.alb_zone_id
}

output "acm_validation_records" {
  description = "CNAME records required to validate the ACM certificate (add at your DNS provider)"
  value       = module.alb.acm_validation_records
}

output "secrets_arn" {
  description = "Secrets Manager ARN"
  value       = module.secrets.secret_arn
}

output "secrets_name" {
  description = "Secrets Manager name"
  value       = module.secrets.secret_name
}

output "infrastructure_summary" {
  description = "Infrastructure summary"
  value = {
    region           = var.aws_region
    domain           = var.domain_name
    wordpress_url    = "https://${var.wordpress_subdomain}.${var.domain_name}"
    microservice_url = "https://${var.microservice_subdomain}.${var.domain_name}"
    alb_dns          = module.alb.alb_dns_name
    rds_endpoint     = module.rds.rds_address
    rds_database     = var.rds_db_name
    ecs_cluster      = module.ecs.ecs_cluster_name
    dns_note         = "Point wordpress/microservice hostnames to the ALB (CNAME or Route53 alias). Validate ACM using acm_validation_records output."
  }
}

output "ec2_instance_eips" {
  description = "Elastic IPs for ec2-instance* and ec2-docker*"
  value       = module.ec2_nginx_instances.eip_public_ips
}

output "ec2_alb_dns_name" {
  description = "ALB DNS name for ec2-alb-* hostnames"
  value       = module.ec2_alb.alb_dns_name
}

output "ec2_instance_urls" {
  description = "HTTPS URLs to access instance subdomains (cert may warn due to Let's Encrypt timing)"
  value = {
    ec2_instance1 = "https://${var.ec2_instance1_subdomain}.${var.domain_name}"
    ec2_docker1   = "https://${var.ec2_docker1_subdomain}.${var.domain_name}"
    ec2_instance2 = "https://${var.ec2_instance2_subdomain}.${var.domain_name}"
    ec2_docker2   = "https://${var.ec2_docker2_subdomain}.${var.domain_name}"
  }
}
