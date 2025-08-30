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
variable "volunteers_apply_lambda_arn" {
  description = "ARN of the Volunteers Apply Lambda function"
  type        = string
}

variable "volunteers_apply_lambda_function_name" {
  description = "Function name of the Volunteers Apply Lambda"
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

# Courses Lambda Variables
variable "courses_get_lambda_arn" {
  description = "ARN of the Courses GET Lambda function"
  type        = string
}

variable "courses_get_lambda_function_name" {
  description = "Function name of the Courses GET Lambda"
  type        = string
}

variable "courses_get_by_id_lambda_arn" {
  description = "ARN of the Courses GET by ID Lambda function"
  type        = string
}

variable "courses_get_by_id_lambda_function_name" {
  description = "Function name of the Courses GET by ID Lambda"
  type        = string
}

variable "courses_post_lambda_arn" {
  description = "ARN of the Courses POST Lambda function"
  type        = string
}

variable "courses_post_lambda_function_name" {
  description = "Function name of the Courses POST Lambda"
  type        = string
}

variable "courses_put_lambda_arn" {
  description = "ARN of the Courses PUT Lambda function"
  type        = string
}

variable "courses_put_lambda_function_name" {
  description = "Function name of the Courses PUT Lambda"
  type        = string
}

variable "courses_delete_lambda_arn" {
  description = "ARN of the Courses DELETE Lambda function"
  type        = string
}

variable "courses_delete_lambda_function_name" {
  description = "Function name of the Courses DELETE Lambda"
  type        = string
}

# Registrations Lambda Variables
variable "registrations_post_lambda_arn" {
  description = "ARN of the Registrations POST Lambda function"
  type        = string
}

variable "registrations_post_lambda_function_name" {
  description = "Function name of the Registrations POST Lambda"
  type        = string
}

variable "registrations_get_lambda_arn" {
  description = "ARN of the Registrations GET Lambda function"
  type        = string
}

variable "registrations_get_lambda_function_name" {
  description = "Function name of the Registrations GET Lambda"
  type        = string
}

variable "registrations_put_lambda_arn" {
  description = "ARN of the Registrations PUT Lambda function"
  type        = string
}

variable "registrations_put_lambda_function_name" {
  description = "Function name of the Registrations PUT Lambda"
  type        = string
}

# Messages Lambda Variables
variable "messages_post_lambda_arn" {
  description = "ARN of the Messages POST Lambda function"
  type        = string
}

variable "messages_post_lambda_function_name" {
  description = "Function name of the Messages POST Lambda"
  type        = string
}

variable "messages_get_lambda_arn" {
  description = "ARN of the Messages GET Lambda function"
  type        = string
}

variable "messages_get_lambda_function_name" {
  description = "Function name of the Messages GET Lambda"
  type        = string
}

# Admin Stats Lambda Variables
variable "admin_stats_get_lambda_arn" {
  description = "ARN of the Admin Stats GET Lambda function"
  type        = string
}

variable "admin_stats_get_lambda_function_name" {
  description = "Function name of the Admin Stats GET Lambda"
  type        = string
}

# Payment Lambda Variables
variable "payments_create_order_lambda_arn" {
  description = "ARN of the Payments Create Order Lambda function"
  type        = string
}

variable "payments_create_order_lambda_function_name" {
  description = "Function name of the Payments Create Order Lambda"
  type        = string
}

variable "payments_webhook_lambda_arn" {
  description = "ARN of the Payments Webhook Lambda function"
  type        = string
}

variable "payments_webhook_lambda_function_name" {
  description = "Function name of the Payments Webhook Lambda"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
