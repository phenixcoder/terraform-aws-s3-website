output "name" {
  value = var.name
}
output "domain" {
  value = aws_route53_record.website_domain.fqdn
}
output "s3_bucket" {
  value = aws_s3_bucket.website_bucket.id
}
output "s3_bucket_domain" {
  value = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
}
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}