# Challenge 4 — GitHub Actions (CI/CD)

## Repository layout

| Path | Purpose |
|------|---------|
| [`microservice/app.js`](../microservice/app.js) | Node.js app — responds with `Hello from Microservice` |
| [`microservice/Dockerfile`](../microservice/Dockerfile) | Container image (port 3000) |
| [`.github/workflows/deploy-microservice.yml`](../.github/workflows/deploy-microservice.yml) | Build → **ECR** → **ECS** deploy |

> Requirement text says “Push to ECS and Deploy to ECR”; the correct flow is **push image to ECR**, then **deploy to ECS** (as implemented in the workflow).

## Prerequisites

1. **Challenge 1** applied (`terraform/challenge1`) — creates ECR repo `cloudzenia/microservice`, ECS cluster, and service.
2. GitHub repository contains this code.
3. Repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

## Workflow behavior

On push to `main` under `microservice/**` (or manual **workflow_dispatch**):

1. Build Docker image from `microservice/`
2. Tag with commit SHA and push to ECR `cloudzenia/microservice`
3. Register new ECS task definition revision with that image
4. Update service `cloudzenia-microservice-service` with forced deployment

## One-time local bootstrap (optional)

If ECS fails before the first GitHub run:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
cd microservice
docker build -t cloudzenia/microservice:latest .
docker tag cloudzenia/microservice:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudzenia/microservice:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudzenia/microservice:latest
```

Replace `<account-id>` with your AWS account ID from `terraform/challenge1` outputs (`microservice_ecr_repo_url`).

## Verify

- `https://microservice.<your-domain>/` → `Hello from Microservice`
- ECS console → service running task with image tag = latest commit SHA
