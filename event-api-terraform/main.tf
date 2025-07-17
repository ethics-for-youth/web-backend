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

resource "aws_apigatewayv2_api" "api" {
  name          = "EventAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
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
  api_id            = aws_apigatewayv2_api.api.id
  route_key         = "POST /events"
  api_execution_arn = aws_apigatewayv2_api.api.execution_arn
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer] 
}

module "get_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "GetEvent"
  lambda_zip        = "lambda_functions/getEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  api_id            = aws_apigatewayv2_api.api.id
  route_key         = "GET /events/{id}"
  api_execution_arn = aws_apigatewayv2_api.api.execution_arn
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer] 
}

module "list_events" {
  source            = "./modules/lambda_api"
  lambda_name       = "ListEvents"
  lambda_zip        = "lambda_functions/listEvents.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  api_id            = aws_apigatewayv2_api.api.id
  route_key         = "GET /events"
  api_execution_arn = aws_apigatewayv2_api.api.execution_arn
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer] 
}

module "update_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "UpdateEvent"
  lambda_zip        = "lambda_functions/updateEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  api_id            = aws_apigatewayv2_api.api.id
  route_key         = "PATCH /events/{id}"
  api_execution_arn = aws_apigatewayv2_api.api.execution_arn
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer] 
}

module "delete_event" {
  source            = "./modules/lambda_api"
  lambda_name       = "DeleteEvent"
  lambda_zip        = "lambda_functions/deleteEvent.zip"
  handler           = "index.handler"
  runtime           = "nodejs18.x"
  api_id            = aws_apigatewayv2_api.api.id
  route_key         = "DELETE /events/{id}"
  api_execution_arn = aws_apigatewayv2_api.api.execution_arn
  lambda_role       = aws_iam_role.lambda_role.arn
  lambda_layers     = [local.aws_sdk_v2_layer] 
}