# Terraform AWS S3 Website Module

## Example usage
```hcl
module "example_website" {
  name           = "example-portal"
  source         = "phenixcoder/terraform-aws-s3-website"
  hosted_zone_id = var.route53_zone_id
  domain_name    = local.environment_domain_name
  sub_domain     = "sub"
  environment    = var.environment
}
```
