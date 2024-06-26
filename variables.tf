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

variable "environment" {
  type        = string
  description = "Deployment Environment Tag"
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

variable "expose_outputs_to_parameters" {
  type        = bool
  default     = false
  description = "Expose the outputs of this module as parameters"
}

variable "parameter_prefix" {
  type        = string
  default     = ""
  description = "Prefix to use for the parameters"
  validation {
    condition     = length(regex("^/[a-zA-Z0-9/_-]+$", var.parameter_prefix)) > 0 || var.parameter_prefix == ""
    error_message = "The prefix can have alphabets and numbers with symbols (-_) and no spaces. Must start with /"
  }
}

variable "index_document" {
  type        = string
  default     = "index.html"
  description = "The index document for the website"
  validation {
    condition     = length(regex("^[.a-zA-Z0-9/_-]+$", var.index_document)) > 0
    error_message = "The prefix can have alphabets and numbers with symbols (-_.) and no spaces."
  }
}

variable "error_document" {
  type        = string
  default     = "error.html"
  description = "The error document for the website"
  validation {
    condition     = length(regex("^[.a-zA-Z0-9/_-]+$", var.error_document)) > 0
    error_message = "The prefix can have alphabets and numbers with symbols (-_.) and no spaces."
  }
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