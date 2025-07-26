variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "get_lambda_arn" {
  description = "ARN of the GET Lambda function to integrate"
  type        = string
}

variable "post_lambda_arn" {
  description = "ARN of the POST Lambda function to integrate"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the API Gateway resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region for constructing the invoke URL"
  type        = string
}
