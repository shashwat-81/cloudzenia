variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project_name" {
  type    = string
  default = "cloudzenia"
}

variable "domain_name" {
  description = "DNS suffix (e.g. duckdns.org)"
  type        = string
}

variable "static_subdomain" {
  description = "Subdomain for static site (FQDN: static_subdomain.domain_name)"
  type        = string
  default     = "static-s3-clodzenia"
}

variable "enable_custom_domain" {
  description = "Attach ACM cert and static-s3.<domain> alias to CloudFront (needs DNS CNAME validation)"
  type        = bool
  default     = false
}

variable "enable_geo_restriction" {
  description = "Block listed countries at CloudFront edge"
  type        = bool
  default     = true
}

variable "geo_restricted_countries" {
  description = "ISO 3166-1 alpha-2 codes to block (geo blacklist)"
  type        = list(string)
  default     = ["IN", "IR", "KP", "SY"]
}

variable "s3_bucket_name" {
  description = "Optional S3 bucket name override (globally unique). Default: project-static-site-<account-id>"
  type        = string
  default     = null
}
