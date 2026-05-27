module "static_site" {
  source = "../modules/static_site"

  providers = {
    aws.acm = aws.acm
  }

  project_name             = var.project_name
  environment              = var.environment
  domain_name              = var.domain_name
  static_subdomain           = var.static_subdomain
  enable_custom_domain       = var.enable_custom_domain
  enable_geo_restriction     = var.enable_geo_restriction
  geo_restricted_countries   = var.geo_restricted_countries
  s3_bucket_name             = var.s3_bucket_name
}
