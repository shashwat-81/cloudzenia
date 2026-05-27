
## Project Structure

```
cloudzenia/
├── README.md                                # This file
├── terraform/                               # Infrastructure as Code (IaC) root
│   ├── main.tf                              # Pointer only — always cd into challenge directories
│   ├── modules/                             # Reusable Terraform modules (shared across challenges)
│   │   ├── vpc/                             # VPC, subnets, NAT gateway, routing
│   │   ├── security/                        # Security groups for ALB, ECS, RDS, EC2
│   │   ├── rds/                             # RDS MySQL database with automated backups
│   │   ├── secrets/                         # AWS Secrets Manager for DB credentials
│   │   ├── iam/                             # IAM roles and policies for ECS tasks
│   │   ├── ecr/                             # Elastic Container Registry for microservice
│   │   ├── ecs/                             # ECS cluster, task definitions, services, auto-scaling
│   │   ├── alb/                             # Application Load Balancer with HTTPS/SSL
│   │   │   └── certs/                       # Self-signed SSL certificate generation
│   │   ├── ec2_nginx_instances/             # EC2 instances with NGINX
│   │   ├── ec2_alb/                         # EC2-level Application Load Balancer
│   │   ├── ec2_cloudwatch/                  # CloudWatch monitoring for EC2
│   │   └── static_site/                     # S3 + CloudFront static site (Challenge 5)
│   │       └── www/index.html               # Static page served via CloudFront
│   ├── challenge1/                          # Challenge 1: ECS, ALB, RDS, Secrets Manager
│   │   ├── main.tf                          # Orchestrates all modules
│   │   ├── variables.tf                     # Input variables (domain, passwords, etc.)
│   │   ├── outputs.tf                       # Outputs (ALB DNS, URLs, etc.)
│   │   ├── provider.tf                      # AWS provider configuration
│   │   ├── terraform.tfvars.example         # Example variable values
│   │   └── README.md                        # Challenge 1 documentation
│   ├── challenge2/                          # Challenge 2: EC2, NGINX, Docker, Let's Encrypt
│   │   ├── main.tf, variables.tf, etc.      # Similar structure to challenge1
│   │   └── README.md
│   ├── challenge3/                          # Challenge 3: Observability (CloudWatch, logs)
│   │   └── README.md
│   ├── challenge5/                          # Challenge 5: S3 + CloudFront + geo restriction
│   │   ├── main.tf, variables.tf, outputs.tf, provider.tf
│   │   ├── terraform.tfvars.example
│   │   └── README.md
│   └── terraform.tfstate*                   # Terraform state files (do not commit)
├── microservice/                            # Node.js microservice
│   ├── app.js                               # Express.js application
│   ├── package.json                         # Node.js dependencies
│   ├── Dockerfile                           # Docker image for microservice
│   └── README.md                            # Microservice documentation
├── challenge4/                              # Challenge 4: GitHub Actions CI/CD
│   ├── README.md                            # Workflow instructions
│   └── Dockerfile.wordpress                 # Custom WordPress image (if using)
├── .github/
│   └── workflows/
│       └── deploy-microservice.yml          # GitHub Actions workflow: build → ECR → ECS deploy
└── .gitignore                               # Excludes terraform state, .tfvars, etc.
```

### Key Components by Challenge

**Challenge 1 (ECS, ALB, RDS, Secrets):**

- VPC with public/private subnets across 2 AZs
- RDS MySQL database in private subnets with automated backups
- ECS cluster with 2 services (WordPress + Microservice) running in private subnets
- Application Load Balancer in public subnets with HTTPS redirection
- Auto-scaling for both ECS services based on CPU/Memory
- Secrets Manager storing RDS credentials (non-rotating)
- IAM roles granting ECS tasks permission to access secrets

**Challenge 2 (EC2, NGINX, Docker):**

- Separate VPC infrastructure
- 2 EC2 instances in private subnets with public IP via EIP
- NGINX and Docker installed on each instance
- EC2 Application Load Balancer
- Let's Encrypt SSL certificates

**Challenge 3 (Observability):**

- CloudWatch monitoring
- Memory utilization metrics
- NGINX access logs collection

**Challenge 4 (GitHub Actions):**

- Automated CI/CD pipeline
- Build microservice Docker image
- Push to ECR
- Deploy to ECS

**Challenge 5 (S3 + CloudFront, optional):**

- Private S3 bucket with static `index.html`
- CloudFront distribution (caching, HTTPS)
- Geo-restriction blacklist (configurable countries)

## Deploy order

```bash
# 1 — ECS stack (creates ECR repo)
cd terraform/challenge1
cp terraform.tfvars.example terraform.tfvars   # edit domain + password
terraform init && terraform apply

# Bootstrap microservice image (once) before ECS service stabilizes, OR push via Challenge 4
cd ../../microservice
# docker build/push to ECR — see challenge4/README.md

# 2 — EC2 stack (separate VPC)
cd ../challenge2
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
# Point DNS A records at EIP outputs; point ec2-alb-* at ec2 ALB DNS name

# 3 — Observability (reads challenge2 state)
cd ../challenge3
terraform init && terraform apply

# 4 — GitHub Actions: push microservice/ to main (or workflow_dispatch)
#     See challenge4/README.md — secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

# 5 — Optional: S3 + CloudFront static site
cd ../challenge5
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
# Use static_site_url output (CloudFront HTTPS URL)
```

## DNS (DuckDNS or similar)

After each apply, create records for your `domain_name`:

- **Challenge 1:** `wordpress-clodzenia`, `microservice-clodzenia` → ALB DNS name
- **Challenge 2:** `ec2-alb-instance-clodzenia`, `ec2-alb-docker-clodzenia` → EC2 ALB DNS name (A record to ALB IP)
- **Challenge 5:** Use CloudFront URL (no fixed IP for DuckDNS A record); optional CNAME if your DNS supports it

## Live Links

| Application          | URL | Description |
| -------------------- | --- | ----------- |
| **WordPress**        | https://wordpress-clodzenia.duckdns.org | WordPress CMS on ECS + RDS |
| **WordPress Admin**  | https://wordpress-clodzenia.duckdns.org/wp-admin/ | Admin login |
| **Microservice**     | https://microservice-clodzenia.duckdns.org | Node.js — `Hello from Microservice` |
| **EC2 NGINX (ALB)**  | https://ec2-alb-instance-clodzenia.duckdns.org | NGINX via EC2 ALB |
| **EC2 Docker (ALB)** | https://ec2-alb-docker-clodzenia.duckdns.org | Docker container via EC2 ALB |
| **Static S3 (CF)**   | https://d13bcx3g377e4n.cloudfront.net | S3 origin + CloudFront CDN (Challenge 5) |

> **Note:** Challenges 1–2 use self-signed certificates on ALBs; browser warnings are expected. Challenge 5 uses CloudFront’s default certificate on `*.cloudfront.net`.

## GitHub secrets (Challenge 4)

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

IAM user needs ECR push and ECS `RegisterTaskDefinition` / `UpdateService` on the Challenge 1 cluster.

## Challenge documentation

| Challenge | Docs |
|-----------|------|
| 1 | [`terraform/challenge1/README.md`](terraform/challenge1/README.md) |
| 2 | [`terraform/challenge2/README.md`](terraform/challenge2/README.md) |
| 3 | [`terraform/challenge3/README.md`](terraform/challenge3/README.md) |
| 4 | [`challenge4/README.md`](challenge4/README.md) |
| 5 | [`challenge5/README.md`](terraform/challenge5//README.md) |

## Do not apply from `terraform/` root

The file [`terraform/main.tf`](terraform/main.tf) is only a pointer. Always `cd` into the challenge directory.
