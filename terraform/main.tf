# Validate workspace name and get environment configuration
locals {
  valid_workspaces = ["dev", "qa", "prod"]
  
  # Validate that current workspace is valid
  workspace_validation = can(regex("^(dev|qa|prod)$", terraform.workspace)) ? null : file("ERROR: Invalid workspace '${terraform.workspace}'. Valid workspaces are: ${join(", ", local.valid_workspaces)}")
  
  # Get current environment from workspace
  current_environment = terraform.workspace
  
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

# Dependencies Layer
module "dependencies_layer" {
  source = "./modules/lambda_layer"
  
  layer_name      = "${var.project_name}-${local.current_environment}-dependencies-layer"
  layer_zip_path  = "${path.root}/layers/dependencies.zip"
  description     = "Shared dependencies for Lambda functions - ${local.current_environment}"
}

# Utility Layer
module "utility_layer" {
  source = "./modules/lambda_layer"
  
  layer_name      = "${var.project_name}-${local.current_environment}-utility-layer"
  layer_zip_path  = "${path.root}/layers/utility.zip"
  description     = "Shared utility functions for Lambda functions - ${local.current_environment}"
}

# Lambda Functions
module "get_xyz_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-get-xyz"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  source_dir   = "${path.root}/lambda_functions/get_xyz"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  tags = local.common_tags
}

module "post_xyz_lambda" {
  source = "./modules/lambda"
  
  function_name = "${var.project_name}-${local.current_environment}-post-xyz"
  handler      = "index.handler"
  runtime      = "nodejs18.x" 
  source_dir   = "${path.root}/lambda_functions/post_xyz"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  tags = local.common_tags
}

module "api_gateway" {
  source = "./modules/api_gateway"
  
  api_name        = "${var.project_name}-${local.current_environment}-api"
  get_lambda_arn  = module.get_xyz_lambda.lambda_invoke_arn
  post_lambda_arn = module.post_xyz_lambda.lambda_invoke_arn
  region          = var.aws_region
  
  tags = local.common_tags
}
