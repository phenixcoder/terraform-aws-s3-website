module "simple_website" {
  name   = "simple-website"
  source = "phenixcoder/s3-website/aws"

  domain_name     = "example.com"
  ssl_certificate = "SSL Certificate ARN"
}