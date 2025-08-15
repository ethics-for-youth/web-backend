# =============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =============================================================================

environment_configs = {
  prod = {
    # Static Website Hosting
    enable_static_hosting        = true
    static_hosting_bucket_suffix = "efy-static-hosting-prod"
    cors_allowed_origins         = ["https://efy.org.in", "https://www.efy.org.in"]
    cloudfront_price_class       = "PriceClass_All"
    
    # DNS & Domain (enabled for production)
    enable_custom_domain = true
    domain_name          = "efy.org.in"
    certificate_sans     = ["www.efy.org.in"]
    create_www_record    = true
    
    # Application S3 Bucket
    s3_bucket_suffix        = "efy-prod-unique"
    s3_enable_versioning    = true
    s3_sse_algorithm        = "aws:kms"
    s3_kms_key_id           = null
    s3_enable_cors          = true
    s3_cors_allowed_origins = ["https://efy.org.in", "https://www.efy.org.in"]
    
    # S3 Lifecycle
    s3_lifecycle_rules = [
      {
        id     = "optimize_storage_costs"
        status = "Enabled"
        filter = { prefix = "" }
        transitions = [
          { days = 30,  storage_class = "STANDARD_IA" },
          { days = 90,  storage_class = "GLACIER" },
          { days = 365, storage_class = "DEEP_ARCHIVE" }
        ]
      },
      {
        id     = "manage_old_versions"
        status = "Enabled"
        filter = { prefix = "" }
        noncurrent_version_transitions = [
          { noncurrent_days = 30, storage_class = "STANDARD_IA" },
          { noncurrent_days = 90, storage_class = "GLACIER" }
        ]
        noncurrent_version_expiration = { noncurrent_days = 365 }
      }
    ]
    
    # Resource Tags
    tags = {
      Environment = "prod"
      CostCenter  = "production"
    }
  }
}