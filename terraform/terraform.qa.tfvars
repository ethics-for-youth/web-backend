# =============================================================================
# QA ENVIRONMENT CONFIGURATION
# =============================================================================

environment_configs = {
  qa = {
    # Static Website Hosting
    enable_static_hosting        = true
    static_hosting_bucket_suffix = "efy-static-hosting-qa"
    cors_allowed_origins         = ["https://qa.efy.org.in"]
    cloudfront_price_class       = "PriceClass_100"
    
    # DNS & Domain (disabled for QA)
    enable_custom_domain = false
    domain_name          = "qa.efy.org.in"
    certificate_sans     = ["qa.efy.org.in"]
    create_www_record    = false
    
    # Application S3 Bucket
    s3_bucket_suffix        = "efy-qa-unique"
    s3_enable_versioning    = true
    s3_sse_algorithm        = "AES256"
    s3_kms_key_id           = null
    s3_enable_cors          = true
    s3_cors_allowed_origins = ["https://qa.efy.org.in"]
    
    # S3 Lifecycle
    s3_lifecycle_rules = [
      {
        id     = "transition_to_ia"
        status = "Enabled"
        filter = { prefix = "" }
        transitions = [
          { days = 30, storage_class = "STANDARD_IA" }
        ]
      },
      {
        id     = "delete_old_versions"
        status = "Enabled"
        filter = { prefix = "" }
        noncurrent_version_expiration = { noncurrent_days = 90 }
      }
    ]
    
    # Resource Tags
    tags = {
      Environment = "qa"
      CostCenter  = "testing"
    }
  }
}