output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.this.arn
}

output "invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}/xyz"
}
