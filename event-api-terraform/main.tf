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

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

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
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
  resource_path     = "events"
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
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
  resource_path     = "events/{id}"
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
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
  resource_path     = "events"
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
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
  resource_path     = "events/{id}"
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
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer]
  resource_path     = "events/{id}"
}