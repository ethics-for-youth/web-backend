# Development Environment Configuration
environment_configs = {
  dev = {
    backend_bucket = "efy-web-backend-dev-terraform-state-123456"
    backend_table  = "efy-web-backend-dev-terraform-locks"
    tags = {
      Environment = "dev"
      CostCenter  = "development"
    }
  }
} 