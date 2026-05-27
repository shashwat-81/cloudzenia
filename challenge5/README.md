# Challenge 5 — S3 Static Website + CloudFront (Optional)

## Live URL

| Resource | URL |
|----------|-----|
| **Static site (CloudFront)** | https://d13bcx3g377e4n.cloudfront.net |

S3 holds the content; visitors use CloudFront for HTTPS, edge caching, and geo-restriction.

## Repository layout

| Path | Purpose |
|------|---------|
| [`terraform/challenge5/`](../terraform/challenge5/) | Terraform root — apply from here |
| [`terraform/modules/static_site/`](../terraform/modules/static_site/) | S3 bucket, OAC, CloudFront, geo blacklist |
| [`terraform/modules/static_site/www/index.html`](../terraform/modules/static_site/www/index.html) | Static `index.html` uploaded to S3 |

## Requirements covered

- **(a)** Static website content in a private S3 bucket (target hostname: `static-s3.<domain-name>` when using custom DNS)
- **(b)** CloudFront distribution — low latency, HTTPS, caching (default TTL 1 hour)
- **(c)** Geo-restriction blacklist (default: `IN`, `IR`, `KP`, `SY`)

## Deploy

```powershell
cd terraform/challenge5
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform output static_site_url
```

## DNS note (DuckDNS)

CloudFront has no fixed IP. For DuckDNS, use the **CloudFront URL** above. A custom name like `static-s3-clodzenia.duckdns.org` needs CNAME-capable DNS and `enable_custom_domain = true` in `terraform.tfvars`.

## Destroy

```powershell
cd terraform/challenge5
terraform destroy
```

See [`terraform/challenge5/README.md`](../terraform/challenge5/README.md) for variables and geo-restriction testing.
