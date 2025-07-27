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