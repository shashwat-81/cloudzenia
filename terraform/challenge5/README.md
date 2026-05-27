# Challenge 5 — Terraform (S3 + CloudFront)

> Overview and live URL: [`../../challenge5/README.md`](../../challenge5/README.md)

## Live deployment

| Output | Value |
|--------|--------|
| CloudFront domain | `d13bcx3g377e4n.cloudfront.net` |
| **Site URL** | https://d13bcx3g377e4n.cloudfront.net |

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Calls `modules/static_site` |
| `variables.tf` | Region, domain, geo-restriction, optional bucket name |
| `outputs.tf` | `static_site_url`, `cloudfront_domain_name`, `dns_setup` |
| `provider.tf` | AWS + `us-east-1` alias for ACM (custom domain only) |
| `terraform.tfvars.example` | Example values |

## Apply

```powershell
terraform init
terraform apply
```

S3 bucket name defaults to `cloudzenia-static-site-<account-id>` (globally unique).

## Variables (high level)

| Variable | Default | Notes |
|----------|---------|--------|
| `static_subdomain` | `static-s3-clodzenia` | FQDN with `domain_name` |
| `enable_custom_domain` | `false` | `true` needs ACM DNS validation |
| `enable_geo_restriction` | `true` | CloudFront geo blacklist |
| `geo_restricted_countries` | `IN`, `IR`, `KP`, `SY` | ISO 3166-1 alpha-2 |

## Geo-restriction test

From a VPN in a blocked country, requests should return CloudFront **403**.
