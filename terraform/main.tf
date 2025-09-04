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

# S3 Bucket for Application Data
module "app_s3_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = "${var.project_name}-${local.current_environment}-app-data-${local.env_config.s3_bucket_suffix}"

  enable_versioning = local.env_config.s3_enable_versioning
  sse_algorithm     = local.env_config.s3_sse_algorithm
  kms_master_key_id = local.env_config.s3_kms_key_id

  # Security settings
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # CORS configuration for web applications
  enable_cors          = local.env_config.s3_enable_cors
  cors_allowed_origins = local.env_config.s3_cors_allowed_origins
  cors_allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
  cors_allowed_headers = ["*"]

  # Lifecycle rules for cost optimization
  lifecycle_rules = local.env_config.s3_lifecycle_rules

  tags = local.common_tags
}

# S3 Bucket for Media Storage (Dua Audio and Images)
module "media_s3_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = "${var.project_name}-${local.current_environment}-media-${local.env_config.s3_bucket_suffix}"

  enable_versioning = local.env_config.s3_enable_versioning
  sse_algorithm     = local.env_config.s3_sse_algorithm
  kms_master_key_id = local.env_config.s3_kms_key_id

  # Security settings (allowing public read for media files)
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # CORS configuration for web applications
  enable_cors          = local.env_config.s3_enable_cors
  cors_allowed_origins = local.env_config.s3_cors_allowed_origins
  cors_allowed_methods = ["GET", "PUT", "POST", "HEAD"]
  cors_allowed_headers = ["*"]

  # Lifecycle rules for cost optimization
  lifecycle_rules = local.env_config.s3_lifecycle_rules

  tags = local.common_tags
}

# DynamoDB Tables
module "dynamodb" {
  source = "./modules/dynamodb"

  events_table_name        = "${var.project_name}-${local.current_environment}-events"
  competitions_table_name  = "${var.project_name}-${local.current_environment}-competitions"
  volunteers_table_name    = "${var.project_name}-${local.current_environment}-volunteers"
  suggestions_table_name   = "${var.project_name}-${local.current_environment}-suggestions"
  courses_table_name       = "${var.project_name}-${local.current_environment}-courses"
  registrations_table_name = "${var.project_name}-${local.current_environment}-registrations"
  messages_table_name      = "${var.project_name}-${local.current_environment}-messages"
  payments_table_name      = "${var.project_name}-${local.current_environment}-payments"
  duas_table_name          = "${var.project_name}-${local.current_environment}-duas"
  tags = local.common_tags
}

# Dependencies Layer
module "dependencies_layer" {
  source = "./modules/lambda_layer"

  layer_name  = "${var.project_name}-${local.current_environment}-dependencies-layer"
  source_dir  = "../layers/dependencies"
  description = "Shared dependencies for Lambda functions - ${local.current_environment}"
}

# Utility Layer
module "utility_layer" {
  source = "./modules/lambda_layer"

  layer_name  = "${var.project_name}-${local.current_environment}-utility-layer"
  source_dir  = "../layers/utility"
  description = "Shared utility functions for Lambda functions - ${local.current_environment}"
}

# Events Lambda Functions
module "events_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-events-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/events_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
    S3_BUCKET_NAME    = module.app_s3_bucket.bucket_id
  }

  dynamodb_table_arns = [module.dynamodb.events_table_arn]
  s3_bucket_arns      = [module.app_s3_bucket.bucket_arn]

  tags = local.common_tags
}

module "events_get_by_id_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-events-get-by-id"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/events_get_by_id"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
  }

  dynamodb_table_arns = [module.dynamodb.events_table_arn]

  tags = local.common_tags
}

module "events_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-events-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/events_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
  }

  dynamodb_table_arns = [module.dynamodb.events_table_arn]

  tags = local.common_tags
}

module "events_put_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-events-put"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/events_put"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
  }

  dynamodb_table_arns = [module.dynamodb.events_table_arn]

  tags = local.common_tags
}

module "events_delete_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-events-delete"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/events_delete"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME = module.dynamodb.events_table_name
  }

  dynamodb_table_arns = [module.dynamodb.events_table_arn]

  tags = local.common_tags
}

# Competitions Lambda Functions
module "competitions_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-competitions-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/competitions_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]

  tags = local.common_tags
}

module "competitions_get_by_id_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-competitions-get-by-id"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/competitions_get_by_id"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]

  tags = local.common_tags
}

module "competitions_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-competitions-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/competitions_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]

  tags = local.common_tags
}

module "competitions_register_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-competitions-register"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/competitions_register"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]

  tags = local.common_tags
}

module "competitions_results_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-competitions-results"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/competitions_results"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COMPETITIONS_TABLE_NAME = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.competitions_table_arn]

  tags = local.common_tags
}

# Volunteers Lambda Functions
module "volunteers_apply_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-volunteers-apply"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/volunteers_apply"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
  }

  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]

  tags = local.common_tags
}

module "volunteers_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-volunteers-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/volunteers_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
  }

  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]

  tags = local.common_tags
}

module "volunteers_put_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-volunteers-put"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/volunteers_put"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    VOLUNTEERS_TABLE_NAME = module.dynamodb.volunteers_table_name
  }

  dynamodb_table_arns = [module.dynamodb.volunteers_table_arn]

  tags = local.common_tags
}

# Suggestions Lambda Functions
module "suggestions_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-suggestions-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/suggestions_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    SUGGESTIONS_TABLE_NAME = module.dynamodb.suggestions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.suggestions_table_arn]

  tags = local.common_tags
}

module "suggestions_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-suggestions-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/suggestions_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    SUGGESTIONS_TABLE_NAME = module.dynamodb.suggestions_table_name
  }

  dynamodb_table_arns = [module.dynamodb.suggestions_table_arn]

  tags = local.common_tags
}

# Courses Lambda Functions
module "courses_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-courses-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/courses_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COURSES_TABLE_NAME = module.dynamodb.courses_table_name
  }

  dynamodb_table_arns = [module.dynamodb.courses_table_arn]

  tags = local.common_tags
}

module "courses_get_by_id_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-courses-get-by-id"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/courses_get_by_id"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COURSES_TABLE_NAME = module.dynamodb.courses_table_name
  }

  dynamodb_table_arns = [module.dynamodb.courses_table_arn]

  tags = local.common_tags
}

module "courses_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-courses-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/courses_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COURSES_TABLE_NAME = module.dynamodb.courses_table_name
  }

  dynamodb_table_arns = [module.dynamodb.courses_table_arn]

  tags = local.common_tags
}

module "courses_put_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-courses-put"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/courses_put"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COURSES_TABLE_NAME = module.dynamodb.courses_table_name
  }

  dynamodb_table_arns = [module.dynamodb.courses_table_arn]

  tags = local.common_tags
}

module "courses_delete_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-courses-delete"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/courses_delete"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    COURSES_TABLE_NAME = module.dynamodb.courses_table_name
  }

  dynamodb_table_arns = [module.dynamodb.courses_table_arn]

  tags = local.common_tags
}

# Registrations Lambda Functions
module "registrations_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-registrations-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/registrations_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name,
    COURSES_TABLE_NAME       = module.dynamodb.courses_table_name,
    EVENTS_TABLE_NAME        = module.dynamodb.events_table_name,
    COMPETITIONS_TABLE_NAME  = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [
    module.dynamodb.registrations_table_arn,
    module.dynamodb.courses_table_arn,
    module.dynamodb.events_table_arn,
    module.dynamodb.competitions_table_arn
  ]

  tags = local.common_tags
}

module "registrations_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-registrations-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/registrations_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name,
    COURSES_TABLE_NAME       = module.dynamodb.courses_table_name,
    EVENTS_TABLE_NAME        = module.dynamodb.events_table_name,
    COMPETITIONS_TABLE_NAME  = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [
    module.dynamodb.registrations_table_arn,
    module.dynamodb.courses_table_arn,
    module.dynamodb.events_table_arn,
    module.dynamodb.competitions_table_arn
  ]

  tags = local.common_tags
}

module "registrations_put_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-registrations-put"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/registrations_put"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name
  }

  dynamodb_table_arns = [module.dynamodb.registrations_table_arn]

  tags = local.common_tags
}

# Messages Lambda Functions
module "messages_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-messages-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/messages_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    MESSAGES_TABLE_NAME = module.dynamodb.messages_table_name
  }

  dynamodb_table_arns = [module.dynamodb.messages_table_arn]

  tags = local.common_tags
}

module "messages_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-messages-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/messages_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    MESSAGES_TABLE_NAME = module.dynamodb.messages_table_name
  }

  dynamodb_table_arns = [module.dynamodb.messages_table_arn]

  tags = local.common_tags
}

# Admin Stats Lambda Function
module "admin_stats_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-admin-stats-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/admin_stats_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    EVENTS_TABLE_NAME        = module.dynamodb.events_table_name
    COMPETITIONS_TABLE_NAME  = module.dynamodb.competitions_table_name
    VOLUNTEERS_TABLE_NAME    = module.dynamodb.volunteers_table_name
    COURSES_TABLE_NAME       = module.dynamodb.courses_table_name
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name
    MESSAGES_TABLE_NAME      = module.dynamodb.messages_table_name
  }

  dynamodb_table_arns = [
    module.dynamodb.events_table_arn,
    module.dynamodb.competitions_table_arn,
    module.dynamodb.volunteers_table_arn,
    module.dynamodb.courses_table_arn,
    module.dynamodb.registrations_table_arn,
    module.dynamodb.messages_table_arn
  ]

  tags = local.common_tags
}

# Payment Lambda Functions
module "payments_create_order_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-payments-create-order"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/payments_create_order"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    RAZORPAY_KEY_ID          = var.razorpay_key_id
    RAZORPAY_KEY_SECRET      = var.razorpay_key_secret
    PAYMENTS_TABLE_NAME      = module.dynamodb.payments_table_name
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name,
    COURSES_TABLE_NAME       = module.dynamodb.courses_table_name,
    EVENTS_TABLE_NAME        = module.dynamodb.events_table_name,
    COMPETITIONS_TABLE_NAME  = module.dynamodb.competitions_table_name
  }

  dynamodb_table_arns = [
    module.dynamodb.payments_table_arn,
    module.dynamodb.registrations_table_arn,
    module.dynamodb.courses_table_arn,
    module.dynamodb.events_table_arn,
    module.dynamodb.competitions_table_arn,
  ]

  timeout = 30

  tags = local.common_tags
}

module "payments_webhook_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-payments-webhook"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/payments_webhook"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    RAZORPAY_WEBHOOK_SECRET  = var.razorpay_webhook_secret
    PAYMENTS_TABLE_NAME      = module.dynamodb.payments_table_name
    REGISTRATIONS_TABLE_NAME = module.dynamodb.registrations_table_name
  }

  dynamodb_table_arns = [
    module.dynamodb.payments_table_arn,
    module.dynamodb.registrations_table_arn
  ]

  timeout = 30

  tags = local.common_tags
}

# Dua Lambda Functions
module "dua_post_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-dua-post"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/dua_post"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    DUA_TABLE_NAME    = module.dynamodb.duas_table_name
    MEDIA_BUCKET_NAME = module.media_s3_bucket.bucket_id
  }

  dynamodb_table_arns = [module.dynamodb.duas_table_arn]
  s3_bucket_arns      = [module.media_s3_bucket.bucket_arn]

  tags = local.common_tags
}

module "dua_get_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${local.current_environment}-dua-get"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/dua_get"

  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]

  environment_variables = {
    DUA_TABLE_NAME = module.dynamodb.duas_table_name
  }

  dynamodb_table_arns = [module.dynamodb.duas_table_arn]

  tags = local.common_tags
}

# API Gateway for EFY Platform
module "efy_api_gateway" {
  source = "./modules/efy_api_gateway"

  api_name = "${var.project_name}-${local.current_environment}-api"

  # Events Lambda ARNs and Function Names
  events_get_lambda_arn                 = module.events_get_lambda.lambda_invoke_arn
  events_get_lambda_function_name       = module.events_get_lambda.lambda_function_name
  events_post_lambda_arn                = module.events_post_lambda.lambda_invoke_arn
  events_post_lambda_function_name      = module.events_post_lambda.lambda_function_name
  events_get_by_id_lambda_arn           = module.events_get_by_id_lambda.lambda_invoke_arn
  events_get_by_id_lambda_function_name = module.events_get_by_id_lambda.lambda_function_name
  events_put_lambda_arn                 = module.events_put_lambda.lambda_invoke_arn
  events_put_lambda_function_name       = module.events_put_lambda.lambda_function_name
  events_delete_lambda_arn              = module.events_delete_lambda.lambda_invoke_arn
  events_delete_lambda_function_name    = module.events_delete_lambda.lambda_function_name

  # Competitions Lambda ARNs and Function Names
  competitions_get_lambda_arn                 = module.competitions_get_lambda.lambda_invoke_arn
  competitions_get_lambda_function_name       = module.competitions_get_lambda.lambda_function_name
  competitions_post_lambda_arn                = module.competitions_post_lambda.lambda_invoke_arn
  competitions_post_lambda_function_name      = module.competitions_post_lambda.lambda_function_name
  competitions_get_by_id_lambda_arn           = module.competitions_get_by_id_lambda.lambda_invoke_arn
  competitions_get_by_id_lambda_function_name = module.competitions_get_by_id_lambda.lambda_function_name
  competitions_register_lambda_arn            = module.competitions_register_lambda.lambda_invoke_arn
  competitions_register_lambda_function_name  = module.competitions_register_lambda.lambda_function_name
  competitions_results_lambda_arn             = module.competitions_results_lambda.lambda_invoke_arn
  competitions_results_lambda_function_name   = module.competitions_results_lambda.lambda_function_name

  # Volunteers Lambda ARNs and Function Names
  volunteers_apply_lambda_arn           = module.volunteers_apply_lambda.lambda_invoke_arn
  volunteers_apply_lambda_function_name = module.volunteers_apply_lambda.lambda_function_name
  volunteers_get_lambda_arn             = module.volunteers_get_lambda.lambda_invoke_arn
  volunteers_get_lambda_function_name   = module.volunteers_get_lambda.lambda_function_name
  volunteers_put_lambda_arn             = module.volunteers_put_lambda.lambda_invoke_arn
  volunteers_put_lambda_function_name   = module.volunteers_put_lambda.lambda_function_name

  # Suggestions Lambda ARNs and Function Names
  suggestions_post_lambda_arn           = module.suggestions_post_lambda.lambda_invoke_arn
  suggestions_post_lambda_function_name = module.suggestions_post_lambda.lambda_function_name
  suggestions_get_lambda_arn            = module.suggestions_get_lambda.lambda_invoke_arn
  suggestions_get_lambda_function_name  = module.suggestions_get_lambda.lambda_function_name

  # Courses Lambda ARNs and Function Names
  courses_get_lambda_arn                 = module.courses_get_lambda.lambda_invoke_arn
  courses_get_lambda_function_name       = module.courses_get_lambda.lambda_function_name
  courses_get_by_id_lambda_arn           = module.courses_get_by_id_lambda.lambda_invoke_arn
  courses_get_by_id_lambda_function_name = module.courses_get_by_id_lambda.lambda_function_name
  courses_post_lambda_arn                = module.courses_post_lambda.lambda_invoke_arn
  courses_post_lambda_function_name      = module.courses_post_lambda.lambda_function_name
  courses_put_lambda_arn                 = module.courses_put_lambda.lambda_invoke_arn
  courses_put_lambda_function_name       = module.courses_put_lambda.lambda_function_name
  courses_delete_lambda_arn              = module.courses_delete_lambda.lambda_invoke_arn
  courses_delete_lambda_function_name    = module.courses_delete_lambda.lambda_function_name

  # Registrations Lambda ARNs and Function Names
  registrations_post_lambda_arn           = module.registrations_post_lambda.lambda_invoke_arn
  registrations_post_lambda_function_name = module.registrations_post_lambda.lambda_function_name
  registrations_get_lambda_arn            = module.registrations_get_lambda.lambda_invoke_arn
  registrations_get_lambda_function_name  = module.registrations_get_lambda.lambda_function_name
  registrations_put_lambda_arn            = module.registrations_put_lambda.lambda_invoke_arn
  registrations_put_lambda_function_name  = module.registrations_put_lambda.lambda_function_name

  # Messages Lambda ARNs and Function Names
  messages_post_lambda_arn           = module.messages_post_lambda.lambda_invoke_arn
  messages_post_lambda_function_name = module.messages_post_lambda.lambda_function_name
  messages_get_lambda_arn            = module.messages_get_lambda.lambda_invoke_arn
  messages_get_lambda_function_name  = module.messages_get_lambda.lambda_function_name

  # Admin Stats Lambda ARNs and Function Names
  admin_stats_get_lambda_arn           = module.admin_stats_get_lambda.lambda_invoke_arn
  admin_stats_get_lambda_function_name = module.admin_stats_get_lambda.lambda_function_name

  # Payment Lambda ARNs and Function Names
  payments_create_order_lambda_arn           = module.payments_create_order_lambda.lambda_invoke_arn
  payments_create_order_lambda_function_name = module.payments_create_order_lambda.lambda_function_name
  payments_webhook_lambda_arn                = module.payments_webhook_lambda.lambda_invoke_arn
  payments_webhook_lambda_function_name      = module.payments_webhook_lambda.lambda_function_name

# Dua Lambda ARNs and Function Names
  dua_post_lambda_arn           = module.dua_post_lambda.lambda_invoke_arn
  dua_post_lambda_function_name = module.dua_post_lambda.lambda_function_name

  dua_get_lambda_arn           = module.dua_get_lambda.lambda_invoke_arn
  dua_get_lambda_function_name = module.dua_get_lambda.lambda_function_name

  tags = local.common_tags
}

# S3 Bucket for Static Website Hosting
module "static_hosting" {
  count  = local.env_config.enable_static_hosting ? 1 : 0
  source = "./modules/s3_static_hosting"

  bucket_name = "${var.project_name}-${local.current_environment}-static-${local.env_config.static_hosting_bucket_suffix}"

  index_document = "index.html"
  error_document = "error.html"

  enable_cors          = true
  cors_allowed_origins = local.env_config.cors_allowed_origins

  enable_versioning = local.current_environment == "prod"

  tags = local.common_tags
}

# Route 53 Hosted Zone (created first, independent)
module "route53_hosted_zone" {
  count  = local.env_config.enable_custom_domain ? 1 : 0
  source = "./modules/route53"

  domain_name               = local.env_config.domain_name
  cloudfront_domain_name    = ""    # Don't create CloudFront records yet
  cloudfront_hosted_zone_id = ""    # Don't create CloudFront records yet
  create_www_record         = false # Don't create www record yet

  tags = local.common_tags
}

# ACM Certificate (depends only on Route53 hosted zone)
module "acm_certificate" {
  count  = local.env_config.enable_custom_domain ? 1 : 0
  source = "./modules/acm_certificate"

  providers = {
    aws = aws.us_east_1
  }

  domain_name               = local.env_config.domain_name
  subject_alternative_names = local.env_config.certificate_sans
  hosted_zone_id            = length(module.route53_hosted_zone) > 0 ? module.route53_hosted_zone[0].hosted_zone_id : ""

  tags = local.common_tags

  depends_on = [module.route53_hosted_zone]
}

# CloudFront Distribution (depends on S3 and ACM certificate)
module "cloudfront" {
  count  = local.env_config.enable_static_hosting ? 1 : 0
  source = "./modules/cloudfront"

  distribution_name     = "${var.project_name}-${local.current_environment}-static"
  s3_bucket_name        = length(module.static_hosting) > 0 ? module.static_hosting[0].bucket_id : ""
  s3_bucket_domain_name = length(module.static_hosting) > 0 ? module.static_hosting[0].bucket_regional_domain_name : ""
  s3_bucket_arn         = length(module.static_hosting) > 0 ? module.static_hosting[0].bucket_arn : ""

  domain_names = local.env_config.enable_custom_domain ? compact([
    local.env_config.domain_name,
    local.env_config.create_www_record ? "www.${local.env_config.domain_name}" : null
  ]) : []

  comment             = "${var.project_name} ${local.current_environment} static website"
  acm_certificate_arn = local.env_config.enable_custom_domain && length(module.acm_certificate) > 0 ? module.acm_certificate[0].certificate_arn : null
  price_class         = local.env_config.cloudfront_price_class

  # API Gateway Integration
  enable_api_gateway      = local.env_config.enable_api_gateway
  api_gateway_domain_name = local.env_config.enable_api_gateway ? "${module.efy_api_gateway.api_gateway_id}.execute-api.${local.env_config.api_gateway_region}.amazonaws.com" : ""
  api_gateway_region      = local.env_config.api_gateway_region

  custom_error_responses = [
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    },
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  tags = local.common_tags

  depends_on = [module.static_hosting, module.acm_certificate, module.efy_api_gateway]
}

# Route 53 DNS Records for CloudFront (created after CloudFront)
module "route53_dns_records" {
  count  = local.env_config.enable_custom_domain && local.env_config.enable_static_hosting ? 1 : 0
  source = "./modules/route53_dns_records"

  hosted_zone_id            = length(module.route53_hosted_zone) > 0 ? module.route53_hosted_zone[0].hosted_zone_id : ""
  domain_name               = local.env_config.domain_name
  cloudfront_domain_name    = length(module.cloudfront) > 0 ? module.cloudfront[0].distribution_domain_name : ""
  cloudfront_hosted_zone_id = length(module.cloudfront) > 0 ? module.cloudfront[0].distribution_hosted_zone_id : ""
  create_www_record         = local.env_config.create_www_record

  depends_on = [module.cloudfront, module.route53_hosted_zone]
}

