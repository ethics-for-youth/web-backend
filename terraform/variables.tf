variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "efy-web-backend"
}

variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    backend_bucket = string
    backend_table  = string
    tags           = map(string)
  }))
  default = {
    dev = {
      backend_bucket = "efy-web-backend-dev-terraform-state-030382357640"
      backend_table  = "efy-web-backend-dev-terraform-locks"
      tags = {
        Environment = "dev"
        CostCenter  = "development"
      }
    }
    qa = {
      backend_bucket = "efy-web-backend-qa-terraform-state-030382357640"
      backend_table  = "efy-web-backend-qa-terraform-locks"
      tags = {
        Environment = "qa"
        CostCenter  = "testing"
      }
    }
    prod = {
      backend_bucket = "efy-web-backend-prod-terraform-state-"
      backend_table  = "efy-web-backend-prod-terraform-locks"
      tags = {
        Environment = "prod"
        CostCenter  = "production"
      }
    }
  }
}
