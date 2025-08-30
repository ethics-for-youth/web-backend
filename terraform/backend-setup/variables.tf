variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "efy-web-backend"
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    state_bucket_name   = string
    tags                = map(string)
  }))
  default = {
    dev = {
      state_bucket_name   = "efy-web-backend-dev-terraform-state-030382357640"
      tags = {
        Environment = "dev"
        CostCenter  = "development"
      }
    }
    qa = {
      state_bucket_name   = "efy-web-backend-qa-terraform-state-030382357640"
      tags = {
        Environment = "qa"
        CostCenter  = "testing"
      }
    }
    prod = {
      state_bucket_name   = "efy-web-backend-prod-terraform-state-657197742641"
      tags = {
        Environment = "prod"
        CostCenter  = "production"
      }
    }
  }
}
