# Validate workspace name and get environment configuration
locals {
  valid_workspaces = ["dev", "qa", "prod"]
  
  # Validate that current workspace is valid (allow default for validation)
  workspace_validation = can(regex("^(dev|qa|prod|default)$", terraform.workspace)) ? null : file("ERROR: Invalid workspace '${terraform.workspace}'. Valid workspaces are: ${join(", ", local.valid_workspaces)}")
  
  # Get current environment from workspace (default to dev for validation)
  current_environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  
  # Get environment-specific configuration
  env_config = var.environment_configs[local.current_environment]
  
  # Common tags for all resources
  common_tags = merge(
    {
      Name        = "${var.project_name}-${local.current_environment}"
      Project     = var.project_name
      Environment = local.current_environment
      ManagedBy   = "terraform"
      Workspace   = terraform.workspace
    },
    local.env_config.tags
  )
}

# DynamoDB Tables
module "dynamodb" {
  source = "./modules/dynamodb"
  
  events_table_name       = "${var.project_name}-${local.current_environment}-events"
  competitions_table_name = "${var.project_name}-${local.current_environment}-competitions"
  volunteers_table_name   = "${var.project_name}-${local.current_environment}-volunteers"
  suggestions_table_name  = "${var.project_name}-${local.current_environment}-suggestions"
  
  tags = local.common_tags
}

# Dependencies Layer
module "dependencies_layer" {
  source = "./modules/lambda_layer"
  
  layer_name      = "${var.project_name}-${local.current_environment}-dependencies-layer"
  source_dir      = "../layers/dependencies"
  description     = "Shared dependencies for Lambda functions - ${local.current_environment}"
}

# Utility Layer
module "utility_layer" {
  source = "./modules/lambda_layer"
  
  layer_name      = "${var.project_name}-${local.current_environment}-utility-layer"
  source_dir      = "../layers/utility"
  description     = "Shared utility functions for Lambda functions - ${local.current_environment}"
}

# Events Lambda Functions
module "events_get_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-events-get"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/events_get"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    AWS_REGION       = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  
  tags = local.common_tags
}

module "events_get_by_id_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-events-get-by-id"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/events_get_by_id"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    AWS_REGION       = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  
  tags = local.common_tags
}

module "events_post_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-events-post"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/events_post"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    AWS_REGION       = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  
  tags = local.common_tags
}

module "events_put_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-events-put"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/events_put"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    AWS_REGION       = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  
  tags = local.common_tags
}

module "events_delete_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-events-delete"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/events_delete"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    AWS_REGION       = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  
  tags = local.common_tags
}

# Competitions Lambda Functions
module "competitions_get_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-competitions-get"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/competitions_get"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
    AWS_REGION             = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]
  
  tags = local.common_tags
}

module "competitions_get_by_id_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-competitions-get-by-id"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/competitions_get_by_id"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
    AWS_REGION             = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]
  
  tags = local.common_tags
}

module "competitions_post_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-competitions-post"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/competitions_post"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
    AWS_REGION             = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]
  
  tags = local.common_tags
}

module "competitions_register_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-competitions-register"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/competitions_register"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
    AWS_REGION             = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]
  
  tags = local.common_tags
}

module "competitions_results_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-competitions-results"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/competitions_results"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
    AWS_REGION             = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]
  
  tags = local.common_tags
}

# Volunteers Lambda Functions
module "volunteers_join_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-volunteers-join"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/volunteers_join"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
    AWS_REGION           = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]
  
  tags = local.common_tags
}

module "volunteers_get_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-volunteers-get"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/volunteers_get"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
    AWS_REGION           = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]
  
  tags = local.common_tags
}

module "volunteers_put_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-volunteers-put"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/volunteers_put"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
    AWS_REGION           = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]
  
  tags = local.common_tags
}

# Suggestions Lambda Functions
module "suggestions_post_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-suggestions-post"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/suggestions_post"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    SUGGESTIONS_TABLE_NAME = module.dynamodb.suggestions_table_name
    AWS_REGION            = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.suggestions_table_arn]
  
  tags = local.common_tags
}

module "suggestions_get_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-suggestions-get"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "../lambda_functions/suggestions_get"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    SUGGESTIONS_TABLE_NAME = module.dynamodb.suggestions_table_name
    AWS_REGION            = var.aws_region
  }
  
  dynamodb_table_arns = [module.dynamodb.suggestions_table_arn]
  
  tags = local.common_tags
}

# API Gateway for EFY Platform
module "efy_api_gateway" {
  source = "./modules/efy_api_gateway"
  
  api_name = "${var.project_name}-${local.current_environment}-api"
  
  # Events Lambda ARNs and Function Names
  events_get_lambda_arn               = module.events_get_lambda.lambda_invoke_arn
  events_get_lambda_function_name     = module.events_get_lambda.lambda_function_name
  events_post_lambda_arn              = module.events_post_lambda.lambda_invoke_arn
  events_post_lambda_function_name    = module.events_post_lambda.lambda_function_name
  events_get_by_id_lambda_arn         = module.events_get_by_id_lambda.lambda_invoke_arn
  events_get_by_id_lambda_function_name = module.events_get_by_id_lambda.lambda_function_name
  events_put_lambda_arn               = module.events_put_lambda.lambda_invoke_arn
  events_put_lambda_function_name     = module.events_put_lambda.lambda_function_name
  events_delete_lambda_arn            = module.events_delete_lambda.lambda_invoke_arn
  events_delete_lambda_function_name  = module.events_delete_lambda.lambda_function_name
  
  # Competitions Lambda ARNs and Function Names
  competitions_get_lambda_arn               = module.competitions_get_lambda.lambda_invoke_arn
  competitions_get_lambda_function_name     = module.competitions_get_lambda.lambda_function_name
  competitions_post_lambda_arn              = module.competitions_post_lambda.lambda_invoke_arn
  competitions_post_lambda_function_name    = module.competitions_post_lambda.lambda_function_name
  competitions_get_by_id_lambda_arn         = module.competitions_get_by_id_lambda.lambda_invoke_arn
  competitions_get_by_id_lambda_function_name = module.competitions_get_by_id_lambda.lambda_function_name
  competitions_register_lambda_arn          = module.competitions_register_lambda.lambda_invoke_arn
  competitions_register_lambda_function_name = module.competitions_register_lambda.lambda_function_name
  competitions_results_lambda_arn           = module.competitions_results_lambda.lambda_invoke_arn
  competitions_results_lambda_function_name = module.competitions_results_lambda.lambda_function_name
  
  # Volunteers Lambda ARNs and Function Names
  volunteers_join_lambda_arn               = module.volunteers_join_lambda.lambda_invoke_arn
  volunteers_join_lambda_function_name     = module.volunteers_join_lambda.lambda_function_name
  volunteers_get_lambda_arn                = module.volunteers_get_lambda.lambda_invoke_arn
  volunteers_get_lambda_function_name      = module.volunteers_get_lambda.lambda_function_name
  volunteers_put_lambda_arn                = module.volunteers_put_lambda.lambda_invoke_arn
  volunteers_put_lambda_function_name      = module.volunteers_put_lambda.lambda_function_name
  
  # Suggestions Lambda ARNs and Function Names
  suggestions_post_lambda_arn              = module.suggestions_post_lambda.lambda_invoke_arn
  suggestions_post_lambda_function_name    = module.suggestions_post_lambda.lambda_function_name
  suggestions_get_lambda_arn               = module.suggestions_get_lambda.lambda_invoke_arn
  suggestions_get_lambda_function_name     = module.suggestions_get_lambda.lambda_function_name
  
  tags = local.common_tags
}
