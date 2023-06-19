variable "name" {
  type        = string
  description = "Name for this website"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = length(regex("^[a-zA-Z0-9\\.\\-_]+$", var.name)) > 0
    error_message = "The name can have alphabets and numbers with symbols (.-_) and no spaces."
  }
}

variable "hosting_zone_domain_name" {
  type        = string
  description = "Domain for fetching Hosting Zone ID form Route53. Required for DNS validation. If not passed, FQDN will be used to get Hosting Zone"
  default     = ""
}

variable "hosting_zone_public" {
  type        = bool
  description = "Default true. Set false if hosted zone is private"
  default     = true
}

variable "domain_name" {
  type        = string
  description = "Domain name where this application will be installed"
}
variable "sub_domain_name" {
  type        = string
  description = "subdomain prefixed to generate final domain for the website."
  default     = ""
}

variable "additional_sub_domains" {
  type        = list(string)
  description = "additonal subdomains prefixed to domain_name generate additional domains for the website. e.g. example.com will have additional domain www.example.com. In case of subdomain as app, with domain name example.com and additional domains add1, add2 and www will generate following domains app.example.com, add1.example.com, add2.example.com and www.example.com. If subdomain is passed as app and need to support www for that domain too then additional domain can be set to www.app which will generate www.app.example.com and app.example.com."
  default     = []
}

variable "comment" {
  type        = string
  default     = "default"
  description = "Static Website using AWS S3 Cloudfront ACM and Route53"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the ACM certificate"
}

variable "ssl_certificate" {
  type        = string
  description = "ARN of SSL Certificate"
}

variable "bff" {
  type = list(object({
    path        = string
    api_gateway = string
    origin_path = optional(string)
  }))
  default     = []
  description = "Collection of Backend for frontend configuration when you want to point yoy specific path to an API"
}