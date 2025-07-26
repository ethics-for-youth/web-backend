resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
  
  tags = var.tags
}

# GET method for /xyz
resource "aws_api_gateway_resource" "xyz" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "xyz"
}

resource "aws_api_gateway_method" "get_xyz" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.xyz.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_xyz" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.xyz.id
  http_method = aws_api_gateway_method.get_xyz.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.get_lambda_arn
}

# POST method for /xyz
resource "aws_api_gateway_method" "post_xyz" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.xyz.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_xyz" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.xyz.id
  http_method = aws_api_gateway_method.post_xyz.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.post_lambda_arn
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "get_xyz" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "post_xyz" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.post_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.get_xyz,
    aws_api_gateway_integration.post_xyz
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
}

# API Gateway stage (replaces deprecated stage_name in deployment)
resource "aws_api_gateway_stage" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name = "default"
}
