# AWS Configuration
aws_region = "ap-south-1"

# Project Configuration
project_name = "efy-web-backend"

# Resource Naming (will be automatically generated based on workspace)
# Format: {project-name}-{workspace}-terraform-state-{random-suffix}
state_bucket_name   = "efy-web-backend-dev-terraform-state-123456" # Change this to a unique name
dynamodb_table_name = "efy-web-backend-dev-terraform-locks"

# Feature Flags
enable_versioning = true
enable_encryption = true
