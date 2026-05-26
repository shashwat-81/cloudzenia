variable "project_name" {
  description = "Project name"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "wordpress_subdomain" {
  description = "WordPress subdomain"
  type        = string
}

variable "microservice_subdomain" {
  description = "Microservice subdomain"
  type        = string
}

variable "wordpress_target_group_arn" {
  description = "WordPress target group ARN"
  type        = string
}

variable "microservice_target_group_arn" {
  description = "Microservice target group ARN"
  type        = string
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for DNS records and ACM validation"
  type        = string
  default     = ""
}

variable "enable_acm_dns_validation" {
  description = "Enable ACM DNS validation (requires Route53 or a real DNS provider). Keep false for DuckDNS."
  type        = bool
  default     = false
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "acm_validation_records" {
  description = "If ACM is enabled, add these CNAME records at your DNS provider to validate the certificate"
  value = var.enable_acm_dns_validation ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}

# Application Load Balancer (public subnets)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# HTTP -> HTTPS redirect (site must not be served over plain HTTP)
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

locals {
  dns_names = [
    var.domain_name,
    "${var.wordpress_subdomain}.${var.domain_name}",
    "${var.microservice_subdomain}.${var.domain_name}",
  ]
}

# Free/DuckDNS mode: self-signed cert uploaded to IAM (encrypted HTTPS, but browsers will warn)
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

  dns_names             = local.dns_names
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "self_signed" {
  name_prefix      = "${var.project_name}-self-signed-"
  certificate_body = tls_self_signed_cert.self_signed.cert_pem
  private_key      = tls_private_key.self_signed.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Optional (trusted) ACM cert path for later (requires proper DNS validation).
resource "aws_acm_certificate" "main" {
  count             = var.enable_acm_dns_validation ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.wordpress_subdomain}.${var.domain_name}",
    "${var.microservice_subdomain}.${var.domain_name}",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = (var.enable_acm_dns_validation && var.route53_zone_id != "") ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count           = var.enable_acm_dns_validation ? 1 : 0
  certificate_arn = aws_acm_certificate.main[0].arn

  validation_record_fqdns = var.route53_zone_id != "" ? [
    for record in aws_route53_record.cert_validation : record.fqdn
  ] : []

  timeouts {
    create = "45m"
  }
}

locals {
  listener_certificate_arn = var.enable_acm_dns_validation ? aws_acm_certificate_validation.main[0].certificate_arn : aws_iam_server_certificate.self_signed.arn
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.listener_certificate_arn

  default_action {
    # If the Host header doesn't match our domain-based rules,
    # serve WordPress anyway (so ALB DNS URL works).
    type             = "forward"
    target_group_arn = var.wordpress_target_group_arn
  }
}

resource "aws_lb_listener_rule" "wordpress" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.wordpress_target_group_arn
  }

  condition {
    host_header {
      values = ["${var.wordpress_subdomain}.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "microservice" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = var.microservice_target_group_arn
  }

  condition {
    host_header {
      values = ["${var.microservice_subdomain}.${var.domain_name}"]
    }
  }
}

resource "aws_route53_record" "wordpress" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "${var.wordpress_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "microservice" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "${var.microservice_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
