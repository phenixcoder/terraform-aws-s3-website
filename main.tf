# S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket        = "${local.domain_name}-website"
  force_destroy = true

  tags = merge(
    {
      Name = local.domain_name
    },
    var.tags
  )
}

resource "aws_s3_bucket_website_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
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

resource "aws_s3_bucket_policy" "website_bucket" {
  depends_on = [aws_s3_bucket.website_bucket]
  bucket     = aws_s3_bucket.website_bucket.bucket
  policy     = data.aws_iam_policy_document.CDNReadForGetBucketObjects.json
}

data "aws_iam_policy_document" "CDNReadForGetBucketObjects" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}



############################################################
# Cloudfront Distribution
############################################################



resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment
  price_class         = "PriceClass_All"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
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

      forwarded_values {
        query_string = true

        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

  aliases = concat([local.domain_name], local.additional_sub_domains)

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
    },
    var.tags
  )
}

# Route53

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
resource "aws_route53_record" "website_additional_domains" {
  for_each = { for idx, record in local.additional_sub_domains : idx => record }
  zone_id = data.aws_route53_zone.hosting_zone.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}