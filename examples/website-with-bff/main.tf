module "simple_website" {
  name   = "simple-website"
  source = "phenixcoder/s3-website/aws"

  domain_name     = "example.com"
  ssl_certificate = "SSL Certificate ARN"

  bff = [
    {
      path        = "/api/user"
      api_gateway = "users.microservices.example.com"
    },
    {
      path        = "/api/products"
      api_gateway = "products.microservices.example.com"
    }
  ]
}