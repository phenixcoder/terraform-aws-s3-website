variable "name" {
  type        = string
  description = "Name for this website"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = length(regex("^[a-zA-Z0-9\\.\\-_]+$", var.name)) > 0
    error_message = "The name can have alphabets and numbers with symbols (.-_) and no spaces."
  }
}

variable "hosted_zone_id" {
  type = string
}

variable "domain_name" {
  type        = string
  description = "Domain name where this application will be installed"
}

variable "sub_domain" {
  type        = string
  default     = ""
  description = "Subdomain. If the website needs to be setup on a sub domain of domain name. E.g. subdomain.domain_name.com"
}

variable "comment" {
  type        = string
  default     = "default"
  description = "Static Website using AWS S3 Cloudfront ACM and Route53"
}

variable "environment" {
  type        = string
  description = "Deployment Environment Tag"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the ACM certificate"
}