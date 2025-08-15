variable "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  type        = string
}

variable "domain_name" {
  description = "The primary domain name"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "The CloudFront distribution hosted zone ID"
  type        = string
}

variable "create_www_record" {
  description = "Whether to create a www subdomain record"
  type        = bool
  default     = true
}