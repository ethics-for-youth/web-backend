output "api_url_dev" {
  value       = aws_api_gateway_stage.dev.invoke_url
  description = "The URL for the dev stage of the EventAPI"
}

output "api_url_prod" {
  value       = aws_api_gateway_stage.prod.invoke_url
  description = "The URL for the prod stage of the EventAPI"
}