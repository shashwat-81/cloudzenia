# Challenge 2 — EC2, NGINX, Docker, ALB

## DuckDNS hostnames (flat names, no dots inside)

Create **6 domains** at [duckdns.org](https://www.duckdns.org) and set IPs from `terraform output`:

| DuckDNS domain               | Points to                                 |
| ---------------------------- | ----------------------------------------- |
| `ec2-instance1-clodzenia`    | EIP `instance1` (e.g. 54.159.59.125)      |
| `ec2-docker1-clodzenia`      | **Same** EIP as instance1                 |
| `ec2-instance2-clodzenia`    | EIP `instance2`                           |
| `ec2-docker2-clodzenia`      | **Same** EIP as instance2                 |
| `ec2-alb-instance-clodzenia` | ALB IP (`nslookup` on `ec2_alb_dns_name`) |
| `ec2-alb-docker-clodzenia`   | **Same** ALB IP                           |

In the **ALB-only private subnet** setup, you only need the two **ALB** domains.

## Private subnet + ALB-only access (important)

**Elastic IP requirement conflicts with private subnet best practices, so ALB-based access was implemented.**

For testing/demo, use only:

- `https://ec2-alb-instance-clodzenia.duckdns.org` (Hello from Instance)
- `https://ec2-alb-docker-clodzenia.duckdns.org` (Namaste from Container)

The direct `ec2-instance*` / `ec2-docker*` hostnames are provisioned as labels, but are **not** used for internet access in this “private subnet + ALB-only” configuration.

## Apply / update hostnames

```powershell
cd terraform\challenge2
terraform apply
```

Wait **2–5 minutes** after apply (NGINX + container start). Then read outputs:

- `terraform output ec2_alb_dns_name` (ALB DNS)
- `terraform output ec2_instance_urls` (the two ALB URLs to open)

## Expected outcome

| URL                                      | Response                 |
| ---------------------------------------- | ------------------------ |
| `ec2-alb-instance-clodzenia.duckdns.org` | `Hello from Instance`    |
| `ec2-alb-docker-clodzenia.duckdns.org`   | `Namaste from Container` |

## Links (open these)

- **ALB (Instance)**: `https://ec2-alb-instance-clodzenia.duckdns.org`
- **ALB (Docker)**: `https://ec2-alb-docker-clodzenia.duckdns.org`

Expected:

- Instance link → `Hello from Instance`
- Docker link → `Namaste from Container`

Note: ALB uses a self-signed certificate, so the browser may show a warning. Proceed to the site.

## Common failure

If the browser says “This site can’t be reached”, it is almost always because DuckDNS is pointing to the wrong IP.

Fix:

1. Run `nslookup <ec2_alb_dns_name>` (from `terraform output ec2_alb_dns_name`) to get the ALB IPv4 addresses.
2. In DuckDNS, set both `ec2-alb-instance-clodzenia` and `ec2-alb-docker-clodzenia` to **one of those IPv4 addresses**.
