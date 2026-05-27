# Challenge 2 — EC2, NGINX, Docker, ALB

## DuckDNS hostnames (flat names, no dots inside)

Create **6 domains** at [duckdns.org](https://www.duckdns.org) and set IPs from `terraform output`:

| DuckDNS domain | Points to |
|----------------|-----------|
| `ec2-instance1-clodzenia` | EIP `instance1` (e.g. 54.159.59.125) |
| `ec2-docker1-clodzenia` | **Same** EIP as instance1 |
| `ec2-instance2-clodzenia` | EIP `instance2` |
| `ec2-docker2-clodzenia` | **Same** EIP as instance2 |
| `ec2-alb-instance-clodzenia` | ALB IP (`nslookup` on `ec2_alb_dns_name`) |
| `ec2-alb-docker-clodzenia` | **Same** ALB IP |

URLs: `https://ec2-instance1-clodzenia.duckdns.org`, etc.

## Apply / update hostnames

```powershell
cd terraform\challenge2
terraform apply
```

Changing hostnames **replaces EC2 instances** (new user-data + certbot). Wait 5–10 min after apply.

## Expected outcome

| URL | Response |
|-----|----------|
| `ec2-instance*-clodzenia.duckdns.org` | `Hello from Instance` |
| `ec2-docker*-clodzenia.duckdns.org` | `Namaste from Container` |
| `ec2-alb-*-clodzenia.duckdns.org` | Same via ALB (cert warning OK) |

## Challenge 3

```powershell
cd ..\challenge3
terraform apply
```
