terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Validate workspace name
locals {
  valid_workspaces = ["dev", "qa", "prod"]

  # Validate that current workspace is valid
  workspace_validation = can(regex("^(dev|qa|prod)$", terraform.workspace)) ? null : file("ERROR: Invalid workspace '${terraform.workspace}'. Valid workspaces are: ${join(", ", local.valid_workspaces)}")

  # Get current environment from workspace
  current_environment = terraform.workspace

  # Get environment-specific configuration
  env_config = var.environment_configs[local.current_environment]

  # Common tags for all resources
  common_tags = merge(
    {
      Name        = "${var.project_name}-${local.current_environment}"
      Project     = var.project_name
      Environment = local.current_environment
      Purpose     = "terraform-backend"
      ManagedBy   = "terraform"
      Workspace   = terraform.workspace
    },
    local.env_config.tags
  )
}

# S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.env_config.state_bucket_name
  force_destroy = false

  tags = local.common_tags
}

# Enable versioning for the state bucket (conditional)
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption (conditional)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
