variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "static_subdomain" {
  description = "Subdomain for static site (FQDN = static_subdomain.domain_name)"
  type        = string
}

variable "domain_name" {
  description = "DNS suffix (e.g. duckdns.org)"
  type        = string
}

variable "geo_restricted_countries" {
  description = "ISO 3166-1 alpha-2 country codes blocked by CloudFront"
  type        = list(string)
  default     = ["IN", "IR", "KP", "SY"]
}

variable "enable_geo_restriction" {
  description = "Enable CloudFront geo restriction (blacklist)"
  type        = bool
  default     = true
}

variable "enable_custom_domain" {
  description = "Use ACM + custom domain on CloudFront (requires DNS CNAME validation; DuckDNS A-only may not work)"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "s3_bucket_name" {
  description = "Optional fixed S3 bucket name (must be globally unique). Default includes AWS account ID."
  type        = string
  default     = null
}
