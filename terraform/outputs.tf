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

# EFY API Gateway Outputs
output "efy_api_gateway_url" {
  description = "URL of the EFY API Gateway"
  value       = module.efy_api_gateway.api_gateway_invoke_url
}

output "efy_api_gateway_id" {
  description = "ID of the EFY API Gateway"
  value       = module.efy_api_gateway.api_gateway_id
}

# DynamoDB Table Names
output "events_table_name" {
  description = "Name of the Events DynamoDB table"
  value       = module.dynamodb.events_table_name
}

output "competitions_table_name" {
  description = "Name of the Competitions DynamoDB table"
  value       = module.dynamodb.competitions_table_name
}

output "volunteers_table_name" {
  description = "Name of the Volunteers DynamoDB table"
  value       = module.dynamodb.volunteers_table_name
}

output "suggestions_table_name" {
  description = "Name of the Suggestions DynamoDB table"
  value       = module.dynamodb.suggestions_table_name
}

# Lambda Function ARNs
output "events_lambda_arns" {
  description = "ARNs of all Events Lambda functions"
  value = {
    get        = module.events_get_lambda.lambda_arn
    get_by_id  = module.events_get_by_id_lambda.lambda_arn
    post       = module.events_post_lambda.lambda_arn
    put        = module.events_put_lambda.lambda_arn
    delete     = module.events_delete_lambda.lambda_arn
  }
}

output "competitions_lambda_arns" {
  description = "ARNs of all Competitions Lambda functions"
  value = {
    get        = module.competitions_get_lambda.lambda_arn
    get_by_id  = module.competitions_get_by_id_lambda.lambda_arn
    post       = module.competitions_post_lambda.lambda_arn
    register   = module.competitions_register_lambda.lambda_arn
    results    = module.competitions_results_lambda.lambda_arn
  }
}

output "volunteers_lambda_arns" {
  description = "ARNs of all Volunteers Lambda functions"
  value = {
    join = module.volunteers_join_lambda.lambda_arn
    get  = module.volunteers_get_lambda.lambda_arn
    put  = module.volunteers_put_lambda.lambda_arn
  }
}

output "suggestions_lambda_arns" {
  description = "ARNs of all Suggestions Lambda functions"
  value = {
    post = module.suggestions_post_lambda.lambda_arn
    get  = module.suggestions_get_lambda.lambda_arn
  }
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
