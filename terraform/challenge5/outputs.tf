output "bucket_name" {
  value = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.static_site.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Point DNS CNAME here, or open this URL directly"
  value       = module.static_site.cloudfront_domain_name
}

output "static_site_url" {
  description = "HTTPS URL (custom domain if enabled, else CloudFront default domain)"
  value       = module.static_site.static_site_url
}

output "static_site_fqdn" {
  value = module.static_site.static_site_fqdn
}

output "acm_validation_records" {
  value = module.static_site.acm_validation_records
}

output "dns_setup" {
  value = module.static_site.dns_setup
}
