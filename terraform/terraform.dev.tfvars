# =============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =============================================================================

environment_configs = {
  dev = {
    # Static Website Hosting
    enable_static_hosting        = true
    static_hosting_bucket_suffix = "efy-static-hosting-dev"
    cors_allowed_origins         = ["https://dev.efy.org.in"]
    cloudfront_price_class       = "PriceClass_100"
    
    # DNS & Domain
    enable_custom_domain = true
    domain_name          = "dev.efy.org.in"
    certificate_sans     = ["www.dev.efy.org.in"]
    create_www_record    = true
    
    # Application S3 Bucket
    s3_bucket_suffix        = "efy-dev-unique"
    s3_enable_versioning    = true
    s3_sse_algorithm        = "AES256"
    s3_kms_key_id           = null
    s3_enable_cors          = true
    s3_cors_allowed_origins = ["https://dev.efy.org.in"]
    
    # S3 Lifecycle
    s3_lifecycle_rules = [
      {
        id     = "delete_incomplete_multipart_uploads"
        status = "Enabled"
        filter = { prefix = "" }
        expiration = { days = 7 }
      }
    ]
    
    # Resource Tags
    tags = {
      Environment = "dev"
      CostCenter  = "development"
    }
  }
}