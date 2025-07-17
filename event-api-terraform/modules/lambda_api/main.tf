resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_name
  role             = var.lambda_role
  filename         = var.lambda_zip
  handler          = var.handler
  runtime          = var.runtime
  layers           = var.lambda_layers
  source_code_hash = filebase64sha256(var.lambda_zip)
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                  = var.api_id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.lambda.invoke_arn
  integration_method      = "POST"
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = var.api_id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
