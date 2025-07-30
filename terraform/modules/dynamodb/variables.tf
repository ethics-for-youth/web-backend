variable "events_table_name" {
  description = "Name of the Events DynamoDB table"
  type        = string
}

variable "competitions_table_name" {
  description = "Name of the Competitions DynamoDB table"
  type        = string
}

variable "volunteers_table_name" {
  description = "Name of the Volunteers DynamoDB table"
  type        = string
}

variable "suggestions_table_name" {
  description = "Name of the Suggestions DynamoDB table"
  type        = string
}

variable "courses_table_name" {
  description = "Name of the Courses DynamoDB table"
  type        = string
}

variable "registrations_table_name" {
  description = "Name of the Registrations DynamoDB table"
  type        = string
}

variable "messages_table_name" {
  description = "Name of the Messages DynamoDB table"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
