# Production Environment Configuration
environment_configs = {
  prod = {
    backend_bucket = "efy-web-backend-prod-terraform-state-123456"
    backend_table  = "efy-web-backend-prod-terraform-locks"
    tags = {
      Environment = "prod"
      CostCenter  = "production"
    }
  }
} 