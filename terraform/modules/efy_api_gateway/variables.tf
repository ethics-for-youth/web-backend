variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

# Events Lambda Variables
variable "events_get_lambda_arn" {
  description = "ARN of the Events GET Lambda function"
  type        = string
}

variable "events_get_lambda_function_name" {
  description = "Function name of the Events GET Lambda"
  type        = string
}

variable "events_post_lambda_arn" {
  description = "ARN of the Events POST Lambda function"
  type        = string
}

variable "events_post_lambda_function_name" {
  description = "Function name of the Events POST Lambda"
  type        = string
}

variable "events_get_by_id_lambda_arn" {
  description = "ARN of the Events GET by ID Lambda function"
  type        = string
}

variable "events_get_by_id_lambda_function_name" {
  description = "Function name of the Events GET by ID Lambda"
  type        = string
}

variable "events_put_lambda_arn" {
  description = "ARN of the Events PUT Lambda function"
  type        = string
}

variable "events_put_lambda_function_name" {
  description = "Function name of the Events PUT Lambda"
  type        = string
}

variable "events_delete_lambda_arn" {
  description = "ARN of the Events DELETE Lambda function"
  type        = string
}

variable "events_delete_lambda_function_name" {
  description = "Function name of the Events DELETE Lambda"
  type        = string
}

# Competitions Lambda Variables
variable "competitions_get_lambda_arn" {
  description = "ARN of the Competitions GET Lambda function"
  type        = string
}

variable "competitions_get_lambda_function_name" {
  description = "Function name of the Competitions GET Lambda"
  type        = string
}

variable "competitions_post_lambda_arn" {
  description = "ARN of the Competitions POST Lambda function"
  type        = string
}

variable "competitions_post_lambda_function_name" {
  description = "Function name of the Competitions POST Lambda"
  type        = string
}

variable "competitions_get_by_id_lambda_arn" {
  description = "ARN of the Competitions GET by ID Lambda function"
  type        = string
}

variable "competitions_get_by_id_lambda_function_name" {
  description = "Function name of the Competitions GET by ID Lambda"
  type        = string
}

variable "competitions_register_lambda_arn" {
  description = "ARN of the Competitions Register Lambda function"
  type        = string
}

variable "competitions_register_lambda_function_name" {
  description = "Function name of the Competitions Register Lambda"
  type        = string
}

variable "competitions_results_lambda_arn" {
  description = "ARN of the Competitions Results Lambda function"
  type        = string
}

variable "competitions_results_lambda_function_name" {
  description = "Function name of the Competitions Results Lambda"
  type        = string
}

# Volunteers Lambda Variables
variable "volunteers_join_lambda_arn" {
  description = "ARN of the Volunteers Join Lambda function"
  type        = string
}

variable "volunteers_join_lambda_function_name" {
  description = "Function name of the Volunteers Join Lambda"
  type        = string
}

variable "volunteers_get_lambda_arn" {
  description = "ARN of the Volunteers GET Lambda function"
  type        = string
}

variable "volunteers_get_lambda_function_name" {
  description = "Function name of the Volunteers GET Lambda"
  type        = string
}

variable "volunteers_put_lambda_arn" {
  description = "ARN of the Volunteers PUT Lambda function"
  type        = string
}

variable "volunteers_put_lambda_function_name" {
  description = "Function name of the Volunteers PUT Lambda"
  type        = string
}

# Suggestions Lambda Variables
variable "suggestions_post_lambda_arn" {
  description = "ARN of the Suggestions POST Lambda function"
  type        = string
}

variable "suggestions_post_lambda_function_name" {
  description = "Function name of the Suggestions POST Lambda"
  type        = string
}

variable "suggestions_get_lambda_arn" {
  description = "ARN of the Suggestions GET Lambda function"
  type        = string
}

variable "suggestions_get_lambda_function_name" {
  description = "Function name of the Suggestions GET Lambda"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}