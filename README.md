# CloudZenia Infrastructure Challenges

Each challenge has its own Terraform root (or GitHub workflow) so you can deploy and grade them independently.

| Challenge                       | Path                                                                                                                        | What it deploys                                                                 |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **1** — ECS, ALB, RDS, Secrets  | [`terraform/challenge1/`](terraform/challenge1/)                                                                            | VPC, RDS, Secrets Manager, IAM, ECR, ECS (WordPress + microservice), ALB        |
| **2** — EC2, NGINX, Docker, ALB | [`terraform/challenge2/`](terraform/challenge2/)                                                                            | VPC, 2× EC2 in **private** subnets + EIP, NGINX, Docker, EC2 ALB, Let's Encrypt |
| **3** — Observability           | [`terraform/challenge3/`](terraform/challenge3/)                                                                            | CloudWatch RAM metrics + NGINX access logs (via SSM on Challenge 2 instances)   |
| **4** — GitHub Actions          | [`microservice/`](microservice/) + [`.github/workflows/deploy-microservice.yml`](.github/workflows/deploy-microservice.yml) | Build Docker image → push **ECR** → deploy **ECS**                              |

Shared modules: [`terraform/modules/`](terraform/modules/)

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

# 4 — Push to main (or workflow_dispatch) after GitHub secrets are set
```

## DNS (DuckDNS or similar)

After each apply, create records for your `domain_name`:

- **Challenge 1:** `wordpress` and `microservice` → ALB DNS name (`alb_dns_name` output)
- **Challenge 2:** `ec2-instance1`, `ec2-docker1`, `ec2-instance2`, `ec2-docker2` → respective EIPs; `ec2-alb-instance`, `ec2-alb-docker` → EC2 ALB DNS name

## Live Links

| Application          | URL                                            | Description                                                        |
| -------------------- | ---------------------------------------------- | ------------------------------------------------------------------ |
| **WordPress**        | https://wordpress-clodzenia.duckdns.org        | WordPress CMS running in ECS with RDS database backend             |
| **Microservice**     | https://microservice-clodzenia.duckdns.org     | Node.js microservice responding with "Hello from Microservice"     |
| **EC2 NGINX (ALB)**  | https://ec2-alb-instance-clodzenia.duckdns.org | NGINX instance endpoint accessed through Application Load Balancer |
| **EC2 Docker (ALB)** | https://ec2-alb-docker-clodzenia.duckdns.org   | Docker container responding with "Namaste from Container" via ALB  |

> **Note:** All domains use self-signed certificates; browser warnings are expected. The actual domain name depends on your `terraform.tfvars` configuration (e.g., `clodzenia.duckdns.org`).

## GitHub secrets (Challenge 4)

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

IAM user needs ECR push and ECS `RegisterTaskDefinition` / `UpdateService` on the Challenge 1 cluster.

## Do not apply from `terraform/` root

The file [`terraform/main.tf`](terraform/main.tf) is only a pointer. Always `cd` into the challenge directory.
