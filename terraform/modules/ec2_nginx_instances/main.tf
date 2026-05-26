variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 (EIP provides inbound reachability for Let's Encrypt HTTP-01)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID (only allow inbound from ALB)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "domain_name" {
  description = "Base domain name (e.g., clodzenia.duckdns.org)"
  type        = string
}

variable "ec2_instance1_subdomain" {
  description = "ec2-instance1 subdomain (without domain)"
  type        = string
  default     = "ec2-instance1"
}

variable "ec2_docker1_subdomain" {
  description = "ec2-docker1 subdomain (without domain)"
  type        = string
  default     = "ec2-docker1"
}

variable "ec2_instance2_subdomain" {
  description = "ec2-instance2 subdomain (without domain)"
  type        = string
  default     = "ec2-instance2"
}

variable "ec2_docker2_subdomain" {
  description = "ec2-docker2 subdomain (without domain)"
  type        = string
  default     = "ec2-docker2"
}

variable "ec2_alb_instance_subdomain" {
  description = "ec2-alb-instance subdomain (without domain)"
  type        = string
  default     = "ec2-alb-instance"
}

variable "ec2_alb_docker_subdomain" {
  description = "ec2-alb-docker subdomain (without domain)"
  type        = string
  default     = "ec2-alb-docker"
}

variable "certbot_email" {
  description = "Email for Let's Encrypt registration"
  type        = string
  default     = "admin@example.com"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH (not required for challenge automation)"
  type        = string
  default     = null
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  subnet_1 = element(var.private_subnet_ids, 0)
  subnet_2 = element(var.private_subnet_ids, 1)

  instance1_host_instance  = "${var.ec2_instance1_subdomain}.${var.domain_name}"
  instance1_host_docker    = "${var.ec2_docker1_subdomain}.${var.domain_name}"
  instance2_host_instance  = "${var.ec2_instance2_subdomain}.${var.domain_name}"
  instance2_host_docker    = "${var.ec2_docker2_subdomain}.${var.domain_name}"

  alb_host_instance = "${var.ec2_alb_instance_subdomain}.${var.domain_name}"
  alb_host_docker   = "${var.ec2_alb_docker_subdomain}.${var.domain_name}"

  instances = {
    instance1 = {
      subnet_id      = local.subnet_1
      host_instance  = local.instance1_host_instance
      host_docker    = local.instance1_host_docker
    }
    instance2 = {
      subnet_id      = local.subnet_2
      host_instance  = local.instance2_host_instance
      host_docker    = local.instance2_host_docker
    }
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "EC2 security group for NGINX/Docker + HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from ALB only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "this" {
  for_each = local.instances
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${each.key}-eip"
  }
}

resource "aws_iam_role" "ec2_cloudwatch" {
  name = "${var.project_name}-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch" {
  name = "${var.project_name}-ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch.name
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = each.value.subnet_id

  # Instances need public reachability for Let's Encrypt HTTP-01.
  associate_public_ip_address = false

  key_name = var.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch.name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx docker.io

    systemctl enable --now nginx
    systemctl enable --now docker

    # Build a minimal container that serves "Namaste from Container" on port 8080
    mkdir -p /opt/namaste
    cat > /opt/namaste/app.py <<'PY'
    from http.server import BaseHTTPRequestHandler, HTTPServer
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"Namaste from Container")
        def log_message(self, format, *args):
            return
    server = HTTPServer(("0.0.0.0", 8080), Handler)
    server.serve_forever()
    PY

    cat > /opt/namaste/Dockerfile <<'DF'
    FROM python:3.11-slim
    WORKDIR /app
    COPY app.py .
    EXPOSE 8080
    CMD ["python", "app.py"]
    DF

    docker build -t namaste-container /opt/namaste
    docker rm -f namaste-container || true
    docker run -d --name namaste-container -p 8080:8080 namaste-container

    # NGINX config:
    # - ec2-instanceX: return "Hello from Instance"
    # - ec2-dockerX: reverse proxy to localhost:8080
    # - ALB hostnames: also serve correct content (HTTP only; ALB terminates TLS)

    cat > /etc/nginx/sites-available/ec2-hosts.conf <<CONF
    server {
      listen 80;
      server_name ${each.value.host_instance};
      location / {
        default_type text/plain;
        return 200 'Hello from Instance';
      }
    }

    server {
      listen 80;
      server_name ${each.value.host_docker};
      location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
      }
    }

    server {
      listen 80;
      server_name ${local.alb_host_instance};
      location / {
        default_type text/plain;
        return 200 'Hello from Instance';
      }
    }

    server {
      listen 80;
      server_name ${local.alb_host_docker};
      location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
      }
    }
    CONF

    rm -f /etc/nginx/sites-enabled/default || true
    ln -sf /etc/nginx/sites-available/ec2-hosts.conf /etc/nginx/sites-enabled/ec2-hosts.conf
    nginx -t
    systemctl reload nginx

    # ALB-only access: instances stay in private subnets and are not accessed directly over the internet.
  EOF

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

resource "aws_eip_association" "this" {
  for_each = local.instances

  allocation_id = aws_eip.this[each.key].id
  instance_id  = aws_instance.this[each.key].id
}

output "instance_ids" {
  value = [for k, v in aws_instance.this : v.id]
}

output "eip_public_ips" {
  value = { for k, v in aws_eip.this : k => v.public_ip }
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_cloudwatch.name
}

