variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "identity_pool_name" {
  description = "Name of the Cognito Identity Pool"
  type        = string
}

variable "user_pool_domain" {
  description = "Domain name for the Cognito User Pool"
  type        = string
}

variable "cognito_authenticated_role_name" {
  description = "Name of the authenticated IAM role"
  type        = string
}

variable "cognito_unauthenticated_role_name" {
  description = "Name of the unauthenticated IAM role"
  type        = string
}

variable "callback_urls" {
  description = "List of callback URLs for the Cognito User Pool Client"
  type        = list(string)
  default     = ["https://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of logout URLs for the Cognito User Pool Client"
  type        = list(string)
  default     = ["https://localhost:3000/logout"]
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}