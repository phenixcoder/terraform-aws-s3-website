locals {
  domain_name = var.sub_domain_name == "" ? var.domain_name : "${var.sub_domain_name}.${var.domain_name}"
}

data "aws_region" "current_region" {}

data "aws_route53_zone" "hosting_zone" {
  name         = var.domain_name
  private_zone = !var.hosting_zone_public
}