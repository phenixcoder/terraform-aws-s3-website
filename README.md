# Terraform AWS S3 Website Module

## Examples

1. [Simple Website](./examples/simple-website/main.tf)
2. [Simple website with subdomain](./examples/website-with-subdomain/main.tf)
3. [Website with BFF](./examples/website-with-bff/main.tf)
## Example usage
```hcl
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
```
