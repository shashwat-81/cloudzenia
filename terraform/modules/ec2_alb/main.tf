variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
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

variable "target_instance_ids" {
  description = "EC2 instance IDs to register in the target group"
  type        = list(string)
}

variable "instance_http_port" {
  description = "Port on instances for NGINX"
  type        = number
  default     = 80
}

locals {
  alb_host_instance = "${var.ec2_alb_instance_subdomain}.${var.domain_name}"
  alb_host_docker   = "${var.ec2_alb_docker_subdomain}.${var.domain_name}"
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-ec2-alb-sg"
  description = "EC2 challenge ALB SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP redirect"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Self-signed cert for ALB HTTPS (DuckDNS ACM DNS validation often fails)
resource "tls_private_key" "self_signed" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  private_key_pem = tls_private_key.self_signed.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = var.project_name
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "self_signed" {
  name_prefix      = "${var.project_name}-ec2-alb-self-signed-"
  certificate_body = tls_self_signed_cert.self_signed.cert_pem
  private_key      = tls_private_key.self_signed.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "instance" {
  name        = "${var.project_name}-ec2-instance-tg"
  port        = var.instance_http_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200,301,302"
  }
}

resource "aws_lb_target_group_attachment" "this" {
  # Use count (not for_each) because instance IDs are only known after apply.
  # length(var.target_instance_ids) is known (2 instances).
  count = length(var.target_instance_ids)

  target_group_arn = aws_lb_target_group.instance.arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.instance_http_port
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_iam_server_certificate.self_signed.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance.arn
  }
}

resource "aws_lb_listener_rule" "instance" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance.arn
  }

  condition {
    host_header {
      values = [local.alb_host_instance]
    }
  }
}

resource "aws_lb_listener_rule" "docker" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance.arn
  }

  condition {
    host_header {
      values = [local.alb_host_docker]
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

