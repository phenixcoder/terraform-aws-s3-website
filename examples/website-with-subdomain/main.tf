module "simple_website" {
  name   = "simple-website"
  source = "phenixcoder/s3-website/aws"

  domain_name     = "example.com"
  sub_domain      = "app"
  ssl_certificate = "SSL Certificate ARN"
}