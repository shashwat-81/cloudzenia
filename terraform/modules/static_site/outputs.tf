output "bucket_name" {
  value = aws_s3_bucket.static.id
}

output "cloudfront_distribution_id" {
  value = local.distribution.id
}

output "cloudfront_domain_name" {
  value = local.distribution.domain_name
}

output "static_site_fqdn" {
  value = local.fqdn
}

output "static_site_url" {
  value = var.enable_custom_domain ? "https://${local.fqdn}" : "https://${local.distribution.domain_name}"
}

output "acm_validation_records" {
  description = "CNAME records for ACM DNS validation (only when enable_custom_domain = true)"
  value = var.enable_custom_domain ? {
    for dvo in aws_acm_certificate.static[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}

output "dns_setup" {
  value = {
    static_fqdn              = local.fqdn
    cloudfront_domain        = local.distribution.domain_name
    custom_domain_enabled    = var.enable_custom_domain
    geo_restricted_countries = var.enable_geo_restriction ? var.geo_restricted_countries : []
    duckdns_note             = "DuckDNS usually supports A records only. Use the CloudFront URL from static_site_url, or CNAME static-s3-clodzenia to cloudfront_domain if your DNS supports CNAME."
  }
}
