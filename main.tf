data "aws_region" "current_region" {}

locals {
  domain_name = var.sub_domain == "" ? var.domain_name : "${var.sub_domain}.${var.domain_name}"
}

provider "aws" {
  alias  = "cdn"
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket        = "${local.domain_name}-website"
  acl           = "public-read"
  force_destroy = true

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${local.domain_name}-website/*"
        }
    ]
}
EOF

  website {
    index_document = "index.html"
    // Required for SPA Apps.
    error_document = "index.html"
  }

  tags = merge(
    {
      Name = local.domain_name
      Environment : var.environment
    },
    var.tags
  )
}

# SSL Certificate

resource "aws_acm_certificate" "certificate" {
  provider    = aws.cdn
  domain_name = local.domain_name
  // subject_alternative_names = var.subject_alternative_names
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = local.domain_name
      Environment : var.environment
    },
    var.tags,
  )
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosting_zone.id
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "website" {
  provider        = aws.cdn
  certificate_arn = aws_acm_certificate.certificate.arn

  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

############################################################
# Cloudfront Distribution
############################################################

resource "aws_cloudfront_distribution" "cdn" {
  depends_on = [
    aws_acm_certificate_validation.website
  ]

  origin {
    domain_name = "${local.domain_name}-website.s3-website-${data.aws_region.current_region.name}.amazonaws.com"
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment
  default_root_object = "index.html"

  aliases = [local.domain_name]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  tags = merge(
    {
      Name = local.domain_name
      Environment : var.environment
    },
    var.tags
  )

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.certificate.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }
}

# Route53

data "aws_route53_zone" "hosting_zone" {
  zone_id      = var.hosted_zone_id
  private_zone = false
}

resource "aws_route53_record" "website_domain" {
  zone_id = data.aws_route53_zone.hosting_zone.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
