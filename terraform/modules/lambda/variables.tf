variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "source_dir" {
  description = "Source directory for Lambda function"
  type        = string
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs that the Lambda function needs access to"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that the Lambda function needs access to"
  type        = list(string)
  default     = []
}

variable "timeout" {
  description = "Timeout for the Lambda function"
  type        = number
  default     = 30
}
