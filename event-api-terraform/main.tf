provider "aws" {
  region  = var.aws_region
  profile = "030382357640_AdministratorAccess"
}

resource "aws_dynamodb_table" "events" {
  name         = "Events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}

# Attach Lambda Execution Policy
resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda-basic-execution"
  roles      = [
    aws_iam_role.create_event_role.name,
    aws_iam_role.get_event_role.name,
    aws_iam_role.list_events_role.name,
    aws_iam_role.update_event_role.name,
    aws_iam_role.delete_event_role.name
  ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Roles
resource "aws_iam_role" "create_event_role" {
  name = "lambda-create-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "get_event_role" {
  name = "lambda-get-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "list_events_role" {
  name = "lambda-list-events-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "update_event_role" {
  name = "lambda-update-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "delete_event_role" {
  name = "lambda-delete-event-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policies for each Lambda
resource "aws_iam_policy" "create_event_policy" {
  name        = "CreateEventPolicy"
  description = "PutItem access for Events table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:PutItem"],
      Resource = aws_dynamodb_table.events.arn
    }]
  })
}

resource "aws_iam_policy" "get_event_policy" {
  name        = "GetEventPolicy"
  description = "GetItem access for Events table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:GetItem"],
      Resource = aws_dynamodb_table.events.arn
    }]
  })
}

resource "aws_iam_policy" "list_events_policy" {
  name        = "ListEventsPolicy"
  description = "Scan/Query access for Events table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      Resource = aws_dynamodb_table.events.arn
    }]
  })
}

resource "aws_iam_policy" "update_event_policy" {
  name        = "UpdateEventPolicy"
  description = "UpdateItem access for Events table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:UpdateItem"],
      Resource = aws_dynamodb_table.events.arn
    }]
  })
}

resource "aws_iam_policy" "delete_event_policy" {
  name        = "DeleteEventPolicy"
  description = "DeleteItem access for Events table"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:DeleteItem"],
      Resource = aws_dynamodb_table.events.arn
    }]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "create_event_attach" {
  role       = aws_iam_role.create_event_role.name
  policy_arn = aws_iam_policy.create_event_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_event_attach" {
  role       = aws_iam_role.get_event_role.name
  policy_arn = aws_iam_policy.get_event_policy.arn
}

resource "aws_iam_role_policy_attachment" "list_events_attach" {
  role       = aws_iam_role.list_events_role.name
  policy_arn = aws_iam_policy.list_events_policy.arn
}

resource "aws_iam_role_policy_attachment" "update_event_attach" {
  role       = aws_iam_role.update_event_role.name
  policy_arn = aws_iam_policy.update_event_policy.arn
}

resource "aws_iam_role_policy_attachment" "delete_event_attach" {
  role       = aws_iam_role.delete_event_role.name
  policy_arn = aws_iam_policy.delete_event_policy.arn
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "EventAPI"
  description = "REST API for Events"
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "event_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.events.id
  path_part   = "{id}"
}

# CORS for /events
resource "aws_api_gateway_method" "events_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_options_integration" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.events.id
  http_method       = aws_api_gateway_method.events_options.http_method
  type              = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}

resource "aws_api_gateway_method_response" "events_options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "events_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = aws_api_gateway_method_response.events_options_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
  }
}

# CORS for /events/{id}
resource "aws_api_gateway_method" "event_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.event_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "event_id_options_integration" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.event_id.id
  http_method       = aws_api_gateway_method.event_id_options.http_method
  type              = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}

resource "aws_api_gateway_method_response" "event_id_options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.event_id.id
  http_method = aws_api_gateway_method.event_id_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "event_id_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.event_id.id
  http_method = aws_api_gateway_method.event_id_options.http_method
  status_code = aws_api_gateway_method_response.event_id_options_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PATCH,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
  }
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [
    module.create_event,
    module.get_event,
    module.list_events,
    module.update_event,
    module.delete_event
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "dev"
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "prod"
}

locals {
  aws_sdk_v2_layer = "arn:aws:lambda:ap-south-1:030382357640:layer:aws-sdk-v2-layer:1"
}

# Lambda Modules
module "create_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "CreateEvent"
  lambda_zip        = "lambda_functions/createEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.events.id
  http_method       = "POST"
  api_execution_arn = aws_api_gateway_rest_api.api.execution_arn
  lambda_role       = aws_iam_role.create_event_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
}

module "get_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "GetEvent"
  lambda_zip        = "lambda_functions/getEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.event_id.id
  http_method       = "GET"
  api_execution_arn = aws_api_gateway_rest_api.api.execution_arn
  lambda_role       = aws_iam_role.get_event_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
}

module "list_events" {
  source            = "./modules/lambda_api"
  lambda_name       = "ListEvents"
  lambda_zip        = "lambda_functions/listEvents.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.events.id
  http_method       = "GET"
  api_execution_arn = aws_api_gateway_rest_api.api.execution_arn
  lambda_role       = aws_iam_role.list_events_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
}

module "update_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "UpdateEvent"
  lambda_zip        = "lambda_functions/updateEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.event_id.id
  http_method       = "PATCH"
  api_execution_arn = aws_api_gateway_rest_api.api.execution_arn
  lambda_role       = aws_iam_role.update_event_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
}

module "delete_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "DeleteEvent"
  lambda_zip        = "lambda_functions/deleteEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.event_id.id
  http_method       = "DELETE"
  api_execution_arn = aws_api_gateway_rest_api.api.execution_arn
  lambda_role       = aws_iam_role.delete_event_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
}
