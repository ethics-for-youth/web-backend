# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project - used as prefix for all resources"
  type        = string
  default     = "efy-web-backend"
}

# =============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATIONS
# =============================================================================

variable "environment_configs" {
  description = "Environment-specific configurations for dev, qa, and prod"
  type = map(object({
    
    # -----------------------------------------------------------------------------
    # STATIC WEBSITE HOSTING CONFIGURATION
    # -----------------------------------------------------------------------------
    enable_static_hosting        = bool         # Enable S3 static website hosting
    static_hosting_bucket_suffix = string       # Unique suffix for static hosting bucket
    cors_allowed_origins         = list(string) # CORS origins for static hosting
    cloudfront_price_class       = string       # CloudFront pricing tier (PriceClass_100/All)
    
    # -----------------------------------------------------------------------------
    # DNS AND DOMAIN CONFIGURATION
    # -----------------------------------------------------------------------------
    enable_custom_domain = bool         # Enable custom domain with Route53 and SSL
    domain_name          = string       # Primary domain name (e.g., "example.com")
    certificate_sans     = list(string) # Additional domains for SSL certificate
    create_www_record    = bool         # Create www subdomain record
    
    # -----------------------------------------------------------------------------
    # APPLICATION S3 BUCKET CONFIGURATION
    # -----------------------------------------------------------------------------
    s3_bucket_suffix        = string       # Unique suffix for app data bucket
    s3_enable_versioning    = bool         # Enable S3 object versioning
    s3_sse_algorithm        = string       # Server-side encryption (AES256/aws:kms)
    s3_kms_key_id           = string       # KMS key ID for encryption (null for default)
    s3_enable_cors          = bool         # Enable CORS for app bucket
    s3_cors_allowed_origins = list(string) # CORS origins for app bucket
    
    # S3 Lifecycle rules for cost optimization
    s3_lifecycle_rules = list(object({
      id     = string
      status = string
      filter = optional(object({
        prefix = optional(string)
        tags   = optional(map(string))
      }))
      expiration = optional(object({
        days                         = optional(number)
        date                         = optional(string)
        expired_object_delete_marker = optional(bool)
      }))
      transitions = optional(list(object({
        days          = optional(number)
        date          = optional(string)
        storage_class = string
      })))
      noncurrent_version_expiration = optional(object({
        noncurrent_days           = optional(number)
        newer_noncurrent_versions = optional(number)
      }))
      noncurrent_version_transitions = optional(list(object({
        noncurrent_days           = optional(number)
        newer_noncurrent_versions = optional(number)
        storage_class             = string
      })))
    }))
    
    # -----------------------------------------------------------------------------
    # RESOURCE TAGGING
    # -----------------------------------------------------------------------------
    tags = map(string) # Common tags applied to all resources
  }))
  # Empty default - actual values provided via .tfvars files
  default = {}
}
