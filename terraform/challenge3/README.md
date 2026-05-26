# Challenge 3 — EC2 Observability

## Requirements covered

- **RAM utilization** in CloudWatch (`mem_used_percent` via CloudWatch Agent)
- **NGINX access logs** in CloudWatch Logs (`/ec2/nginx/access`)

## Prerequisites

1. **Challenge 2** applied successfully (`terraform/challenge2/terraform.tfstate` must exist).
2. EC2 instances finished user-data (NGINX running, ~5–10 min).
3. Instances registered in **Systems Manager** (IAM profile from Challenge 2 includes `AmazonSSMManagedInstanceCore`).

## Apply

```bash
terraform init
terraform apply
```

Uses [remote state](../challenge2/) to read `ec2_instance_ids`, then runs an SSM document on each instance to install and configure the CloudWatch agent.

## Verify

- **Metrics:** CloudWatch → Metrics → **CWAgent** → `mem_used_percent`
- **Logs:** CloudWatch → Log groups → `/ec2/nginx/access` → streams `i-xxx/nginx-access`

Generate traffic: `curl https://ec2-instance1.<domain>/` then refresh Logs Insights.
