output "ec2_instance_eips" {
  description = "Elastic IPs for ec2-instance* and ec2-docker*"
  value       = module.ec2_nginx_instances.eip_public_ips
}

output "ec2_alb_dns_name" {
  description = "ALB DNS name for ec2-alb-* hostnames"
  value       = module.ec2_alb.alb_dns_name
}

output "ec2_instance_urls" {
  description = "HTTPS URLs to access instance subdomains (certificate may take time)"
  value = {
    ec2_instance1 = "https://${var.ec2_instance1_subdomain}.${var.domain_name}"
    ec2_docker1   = "https://${var.ec2_docker1_subdomain}.${var.domain_name}"
    ec2_instance2 = "https://${var.ec2_instance2_subdomain}.${var.domain_name}"
    ec2_docker2   = "https://${var.ec2_docker2_subdomain}.${var.domain_name}"
    ec2_alb_instance = "https://${var.ec2_alb_instance_subdomain}.${var.domain_name}"
    ec2_alb_docker   = "https://${var.ec2_alb_docker_subdomain}.${var.domain_name}"
  }
}

