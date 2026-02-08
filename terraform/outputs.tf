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

# S3 Bucket Outputs
output "app_s3_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = module.app_s3_bucket.bucket_id
}

output "app_s3_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = module.app_s3_bucket.bucket_arn
}

output "app_s3_bucket_domain_name" {
  description = "Domain name of the application S3 bucket"
  value       = module.app_s3_bucket.bucket_domain_name
}

output "app_s3_bucket_region" {
  description = "Region of the application S3 bucket"
  value       = module.app_s3_bucket.bucket_region
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

# DynamoDB Table Names 
output "duas_table_name" {
  description = "Name of the Duas DynamoDB table"
  value       = module.dynamodb.duas_table_name
}

# Lambda Function ARNs
output "events_lambda_arns" {
  description = "ARNs of all Events Lambda functions"
  value = {
    get       = module.events_get_lambda.lambda_arn
    get_by_id = module.events_get_by_id_lambda.lambda_arn
    post      = module.events_post_lambda.lambda_arn
    put       = module.events_put_lambda.lambda_arn
    delete    = module.events_delete_lambda.lambda_arn
  }
}

output "competitions_lambda_arns" {
  description = "ARNs of all Competitions Lambda functions"
  value = {
    get       = module.competitions_get_lambda.lambda_arn
    get_by_id = module.competitions_get_by_id_lambda.lambda_arn
    post      = module.competitions_post_lambda.lambda_arn
    register  = module.competitions_register_lambda.lambda_arn
    results   = module.competitions_results_lambda.lambda_arn
  }
}

output "volunteers_lambda_arns" {
  description = "ARNs of all Volunteers Lambda functions"
  value = {
    apply = module.volunteers_apply_lambda.lambda_arn
    get   = module.volunteers_get_lambda.lambda_arn
    put   = module.volunteers_put_lambda.lambda_arn
  }
}

output "suggestions_lambda_arns" {
  description = "ARNs of all Suggestions Lambda functions"
  value = {
    post = module.suggestions_post_lambda.lambda_arn
    get  = module.suggestions_get_lambda.lambda_arn
  }
}

# Dua Lambda Function ARNs
output "dua_lambda_arns" {
  description = "ARNs of all Dua Lambda functions"
  value = {
    post = module.dua_post_lambda.lambda_arn
    get  = module.dua_get_lambda.lambda_arn
  }
}
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Static Website Hosting Outputs
output "static_website_bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  value       = length(module.static_hosting) > 0 ? module.static_hosting[0].bucket_id : null
}

output "static_website_bucket_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = length(module.static_hosting) > 0 ? module.static_hosting[0].website_endpoint : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = length(module.cloudfront) > 0 ? module.cloudfront[0].distribution_id : null
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront Distribution domain name"
  value       = length(module.cloudfront) > 0 ? module.cloudfront[0].distribution_domain_name : null
}

output "custom_domain_name" {
  description = "Custom domain name for the website"
  value       = local.env_config.enable_custom_domain ? local.env_config.domain_name : null
}

output "route53_hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = length(module.route53_hosted_zone) > 0 ? module.route53_hosted_zone[0].hosted_zone_id : null
}

output "route53_name_servers" {
  description = "Route 53 hosted zone name servers"
  value       = length(module.route53_hosted_zone) > 0 ? module.route53_hosted_zone[0].hosted_zone_name_servers : null
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = length(module.acm_certificate) > 0 ? module.acm_certificate[0].certificate_arn : null
}

output "website_urls" {
  description = "Website URLs"
  value = {
    cloudfront_url    = length(module.cloudfront) > 0 ? "https://${module.cloudfront[0].distribution_domain_name}" : null
    custom_domain_url = local.env_config.enable_custom_domain ? "https://${local.env_config.domain_name}" : null
    s3_website_url    = length(module.static_hosting) > 0 ? "http://${module.static_hosting[0].website_endpoint}" : null
  }
}
