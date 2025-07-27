output "environment" {
  description = "Current environment (workspace)"
  value       = terraform.workspace
}

output "dependencies_layer_arn" {
  description = "ARN of the dependencies layer"
  value       = module.dependencies_layer.layer_arn
}

output "utility_layer_arn" {
  description = "ARN of the utility layer"
  value       = module.utility_layer.layer_arn
}

output "get_xyz_lambda_arn" {
  description = "ARN of the get_xyz Lambda function"
  value       = module.get_xyz_lambda.lambda_arn
}

output "post_xyz_lambda_arn" {
  description = "ARN of the post_xyz Lambda function"
  value       = module.post_xyz_lambda.lambda_arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.invoke_url
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
