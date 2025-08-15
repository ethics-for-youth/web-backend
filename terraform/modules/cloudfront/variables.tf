variable "distribution_name" {
  description = "Name for the CloudFront distribution"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "domain_names" {
  description = "Custom domain names for the distribution"
  type        = list(string)
  default     = []
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = "CloudFront distribution for static website"
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "allowed_methods" {
  description = "Allowed HTTP methods"
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
  description = "Cached HTTP methods"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy"
  type        = string
  default     = "redirect-to-https"
}

variable "min_ttl" {
  description = "Minimum TTL"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL"
  type        = number
  default     = 31536000
}

variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_All"
}

variable "geo_restriction_type" {
  description = "Type of geo restriction"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  default     = null
}

variable "web_acl_id" {
  description = "AWS WAF Web ACL ID"
  type        = string
  default     = null
}

variable "custom_error_responses" {
  description = "Custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = [
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    },
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}