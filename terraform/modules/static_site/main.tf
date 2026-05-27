data "aws_caller_identity" "current" {}

locals {
  fqdn         = "${var.static_subdomain}.${var.domain_name}"
  bucket_name  = coalesce(var.s3_bucket_name, "${var.project_name}-static-site-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "static" {
  bucket = local.bucket_name

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static.id
  key          = "index.html"
  content_type = "text/html"
  source       = "${path.module}/www/index.html"
  etag         = filemd5("${path.module}/www/index.html")
}

resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${var.project_name}-static-oac"
  description                       = "OAC for S3 static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_acm_certificate" "static" {
  count    = var.enable_custom_domain ? 1 : 0
  provider = aws.acm

  domain_name       = local.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-static-cert"
  }
}

resource "aws_acm_certificate_validation" "static" {
  count    = var.enable_custom_domain ? 1 : 0
  provider = aws.acm

  certificate_arn         = aws_acm_certificate.static[0].arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.static[0].domain_validation_options : dvo.resource_record_name]

  timeouts {
    create = "45m"
  }
}

resource "aws_cloudfront_distribution" "default" {
  count = var.enable_custom_domain ? 0 : 1

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static site (Challenge 5)"
  default_root_object = "index.html"
  price_class         = var.price_class
  wait_for_deployment = true

  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = var.enable_geo_restriction ? "blacklist" : "none"
      locations        = var.enable_geo_restriction ? var.geo_restricted_countries : []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_distribution" "custom" {
  count = var.enable_custom_domain ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static site (Challenge 5)"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = [local.fqdn]
  wait_for_deployment = true

  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = var.enable_geo_restriction ? "blacklist" : "none"
      locations        = var.enable_geo_restriction ? var.geo_restricted_countries : []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.static[0].arn
    ssl_support_method         = "sni-only"
    minimum_protocol_version   = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.static[0]]
}

locals {
  distribution = var.enable_custom_domain ? aws_cloudfront_distribution.custom[0] : aws_cloudfront_distribution.default[0]
}

data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.s3_cloudfront.json

  depends_on = [
    aws_cloudfront_distribution.default,
    aws_cloudfront_distribution.custom,
  ]
}
