output "ec2_instance_ids" {
  description = "EC2 instance IDs (used by Challenge 3 remote state)"
  value       = module.ec2_nginx_instances.instance_ids
}

output "ec2_instance_eips" {
  description = "Elastic IPs — point matching DuckDNS domains here"
  value       = module.ec2_nginx_instances.eip_public_ips
}

output "ec2_alb_dns_name" {
  description = "EC2 ALB DNS — point ec2-alb-*-clodzenia DuckDNS domains here (use ALB IP from nslookup)"
  value       = module.ec2_alb.alb_dns_name
}

output "ec2_instance_urls" {
  description = "URLs (DuckDNS). For private-subnet mode, use ALB URLs only."
  value = {
    ec2_alb_instance = "https://${var.ec2_alb_instance_subdomain}.${var.domain_name}"
    ec2_alb_docker   = "https://${var.ec2_alb_docker_subdomain}.${var.domain_name}"
  }
}

output "duckdns_setup" {
  description = "ALB-only: create these DuckDNS domains and set them to an ALB IPv4 from nslookup."
  value = {
    alb_dns       = module.ec2_alb.alb_dns_name
    domains = {
      (var.ec2_alb_instance_subdomain) = "→ ALB IP (nslookup alb_dns)"
      (var.ec2_alb_docker_subdomain)   = "→ ALB IP (same)"
    }
  }
}
