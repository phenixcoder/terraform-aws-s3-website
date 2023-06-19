locals {
  domain_name = var.sub_domain_name == "" ? var.domain_name : "${var.sub_domain_name}.${var.domain_name}"
  additional_sub_domains = [for subdomain in var.additional_sub_domains: "${subdomain}.${var.domain_name}"]
}

data "aws_region" "current_region" {}

data "aws_route53_zone" "hosting_zone" {
  name         = var.hosting_zone_domain_name == "" ? var.domain_name : var.hosting_zone_domain_name
  private_zone = !var.hosting_zone_public
}