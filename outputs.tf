output "name" {
  value = var.name
}
output "bucket" {
  value = aws_s3_bucket.website_bucket.bucket
}

output "cdn" {
  value = aws_cloudfront_distribution.cdn.id
}

output "domain" {
  value = local.domain_name
}