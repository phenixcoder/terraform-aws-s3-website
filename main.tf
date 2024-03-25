data "aws_region" "current_region" {}

locals {
  domain_name = var.domain_name
}

# S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket        = "${local.domain_name}-website"
  force_destroy = true

  tags = merge(
    {
      Name = local.domain_name
      Environment : var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "website_bucket" {
  depends_on = [
    aws_s3_bucket_public_access_block.website_bucket,
    aws_s3_bucket_ownership_controls.website_bucket
  ]
  bucket = aws_s3_bucket.website_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = data.aws_iam_policy_document.website_bucket.json
}

resource "aws_s3_bucket_website_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_s3_bucket_cors_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

############################################################
# Cloudfront Distribution
############################################################

resource "aws_cloudfront_cache_policy" "no_cache_policy" {
  name        = "${var.name}-${var.environment}-no-cache"
  comment     = "Cache policy to not cache anything. For ${var.name} ${var.environment}. ${var.comment}"
  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }

}

resource "aws_cloudfront_origin_request_policy" "forward_all_reuqest_policy" {
  name    = "${var.name}-${var.environment}-forward-all"
  comment = "Request policy to forward all headers and query strings and cookies. For ${var.name} ${var.environment}. ${var.comment}"
  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allExcept"
    headers {
      items = ["Host"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }

}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment
  price_class         = "PriceClass_All"
  default_root_object = "index.html"

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

  dynamic "origin" {
    for_each = var.bff
    content {
      domain_name = origin.value.api_gateway
      origin_id   = "ApiGatewayOrigin${origin.value.path}"

      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_keepalive_timeout = 5
        origin_read_timeout      = 30
      }

      origin_path = origin.value.origin_path
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.bff
    content {
      allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cached_methods   = ["GET", "HEAD"]
      path_pattern     = "${ordered_cache_behavior.value.path}/*"
      target_origin_id = "ApiGatewayOrigin${ordered_cache_behavior.value.path}"

      origin_request_policy_id = aws_cloudfront_origin_request_policy.forward_all_reuqest_policy.id
      cache_policy_id          = aws_cloudfront_cache_policy.no_cache_policy.id

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.ssl_certificate
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  tags = merge(
    {
      Name = local.domain_name
      Environment : var.environment
    },
    var.tags
  )
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

# Outputs as SSM Parameters
resource "aws_ssm_parameter" "bucket" {
  count = var.expose_outputs_to_parameters && var.parameter_prefix != "" ? 1 : 0

  depends_on = [
    aws_s3_bucket.website_bucket
  ]

  name  = "${var.parameter_prefix}/bucket"
  type  = "String"
  value = aws_s3_bucket.website_bucket.id

  tags = var.tags
}

resource "aws_ssm_parameter" "cdn" {
  count = var.expose_outputs_to_parameters && var.parameter_prefix != "" ? 1 : 0

  depends_on = [
    aws_cloudfront_distribution.cdn
  ]

  name  = "${var.parameter_prefix}/cdn"
  type  = "String"
  value = aws_cloudfront_distribution.cdn.id

  tags = var.tags
}

resource "aws_ssm_parameter" "domain" {
  count = var.expose_outputs_to_parameters && var.parameter_prefix != "" ? 1 : 0

  name  = "${var.parameter_prefix}/domain"
  type  = "String"
  value = local.domain_name

  tags = var.tags
}