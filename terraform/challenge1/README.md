# Challenge 1 — ECS, ALB, RDS, Secrets Manager

## Requirements covered

- ECS cluster and services in **private subnets** (WordPress + custom microservice)
- CPU and memory **auto scaling** on both services
- RDS MySQL in private subnets, automated backups, static `wp_app_user` credentials
- Credentials in **Secrets Manager** (no rotation)
- ECS task pulls DB user/password from Secrets Manager via IAM
- Least-privilege security groups
- Internet-facing ALB in public subnets, **HTTP → HTTPS redirect**, host-based routing for `wordpress.*` and `microservice.*`

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Outputs

- `alb_dns_name` — point WordPress and microservice DNS here
- `microservice_ecr_repo_url` — used by Challenge 4
- `wordpress_url` / `microservice_url`

## Microservice image

Terraform sets the task image to `<ecr_url>:latest`. Push an image via [Challenge 4](../../challenge4/README.md) or a one-time local `docker push` before the ECS service can become healthy.

## Apply errors after `terraform destroy`

| Error | Cause | Fix |
|-------|--------|-----|
| `MalformedCertificate` on IAM cert | Self-signed upload needs `certificate_chain` | Fixed in `modules/alb` — run `terraform apply` again |
| `RepositoryAlreadyExistsException` | ECR repo still in AWS | Set `use_existing_ecr_repository = true` in `terraform.tfvars` (default) |
| Secret *scheduled for deletion* | 7-day recovery from last destroy | `aws secretsmanager delete-secret --secret-id cloudzenia/rds/wordpress --force-delete-without-recovery --region us-east-1` then apply |
| NAT `Elastic IP already associated` | State tracks a **failed** NAT while a **working** NAT already uses the same EIP | See below |

### NAT “EIP already associated” (state mismatch)

Often after a failed apply: AWS has a healthy `cloudzenia-nat-1`, but Terraform state still references a failed NAT id.

```powershell
# 1. Delete any FAILED nat (console or CLI)
aws ec2 delete-nat-gateway --nat-gateway-id <failed-nat-id> --region us-east-1

# 2. Find the AVAILABLE nat in the same VPC and import it
aws ec2 describe-nat-gateways --region us-east-1 --filter "Name=state,Values=available" --query "NatGateways[?Tags[?Key=='Name' && Value=='cloudzenia-nat-1']].NatGatewayId" --output text

cd terraform\challenge1
terraform state rm module.vpc.aws_nat_gateway.main[0]
terraform import module.vpc.aws_nat_gateway.main[0] nat-xxxxxxxx   # id from above
terraform apply
```

```powershell
# Optional cleanup helper
.\scripts\fix-partial-destroy.ps1
cd terraform\challenge1
terraform apply
```
