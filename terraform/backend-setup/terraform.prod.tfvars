# Production Environment Configuration
environment = "prod"

# Resource Naming for Production Environment
state_bucket_name   = "efy-web-backend-prod-terraform-state-"  # Change this to a unique name
dynamodb_table_name = "efy-web-backend-prod-terraform-locks"

# Feature Flags for Production
enable_versioning = true
enable_encryption = true 