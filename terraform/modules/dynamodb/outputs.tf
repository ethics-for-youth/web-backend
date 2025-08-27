output "events_table_name" {
  description = "Name of the Events table"
  value       = aws_dynamodb_table.events.name
}

output "events_table_arn" {
  description = "ARN of the Events table"
  value       = aws_dynamodb_table.events.arn
}

output "competitions_table_name" {
  description = "Name of the Competitions table"
  value       = aws_dynamodb_table.competitions.name
}

output "competitions_table_arn" {
  description = "ARN of the Competitions table"
  value       = aws_dynamodb_table.competitions.arn
}

output "volunteers_table_name" {
  description = "Name of the Volunteers table"
  value       = aws_dynamodb_table.volunteers.name
}

output "volunteers_table_arn" {
  description = "ARN of the Volunteers table"
  value       = aws_dynamodb_table.volunteers.arn
}

output "suggestions_table_name" {
  description = "Name of the Suggestions table"
  value       = aws_dynamodb_table.suggestions.name
}

output "suggestions_table_arn" {
  description = "ARN of the Suggestions table"
  value       = aws_dynamodb_table.suggestions.arn
}

output "courses_table_name" {
  description = "Name of the Courses table"
  value       = aws_dynamodb_table.courses.name
}

output "courses_table_arn" {
  description = "ARN of the Courses table"
  value       = aws_dynamodb_table.courses.arn
}

output "registrations_table_name" {
  description = "Name of the Registrations table"
  value       = aws_dynamodb_table.registrations.name
}

output "registrations_table_arn" {
  description = "ARN of the Registrations table"
  value       = aws_dynamodb_table.registrations.arn
}

output "messages_table_name" {
  description = "Name of the Messages table"
  value       = aws_dynamodb_table.messages.name
}

output "messages_table_arn" {
  description = "ARN of the Messages table"
  value       = aws_dynamodb_table.messages.arn
}

output "payments_table_name" {
  description = "Name of the Payments table"
  value       = aws_dynamodb_table.payments.name
}

output "payments_table_arn" {
  description = "ARN of the Payments table"
  value       = aws_dynamodb_table.payments.arn
}

output "permissions_table_name" {
  description = "Name of the Permissions table"
  value       = aws_dynamodb_table.permissions.name
}

output "permissions_table_arn" {
  description = "ARN of the Permissions table"
  value       = aws_dynamodb_table.permissions.arn
}

output "users_table_name" {
  description = "Name of the Users table"
  value       = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  description = "ARN of the Users table"
  value       = aws_dynamodb_table.users.arn
}

output "volunteer_tasks_table_name" {
  description = "Name of the Volunteer Tasks table"
  value       = aws_dynamodb_table.volunteer_tasks.name
}

output "volunteer_tasks_table_arn" {
  description = "ARN of the Volunteer Tasks table"
  value       = aws_dynamodb_table.volunteer_tasks.arn
}

output "volunteer_applications_table_name" {
  description = "Name of the Volunteer Applications table"
  value       = aws_dynamodb_table.volunteer_applications.name
}

output "volunteer_applications_table_arn" {
  description = "ARN of the Volunteer Applications table"
  value       = aws_dynamodb_table.volunteer_applications.arn
}
