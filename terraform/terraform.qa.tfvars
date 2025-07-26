# QA Environment Configuration
environment_configs = {
  qa = {
    backend_bucket = "efy-web-backend-qa-terraform-state-123456"
    backend_table  = "efy-web-backend-qa-terraform-locks"
    tags = {
      Environment = "qa"
      CostCenter  = "testing"
    }
  }
} 