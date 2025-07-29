resource "aws_api_gateway_rest_api" "efy_api" {
  name = var.api_name

  tags = var.tags
}

# Events Resource
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_resource" "events_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.events.id
  path_part   = "{id}"
}

# Events Methods
resource "aws_api_gateway_method" "events_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_get_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_put" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_delete" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Events Integrations
resource "aws_api_gateway_integration" "events_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.events_get_lambda_arn
}

resource "aws_api_gateway_integration" "events_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.events_post_lambda_arn
}

resource "aws_api_gateway_integration" "events_get_by_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.events_id.id
  http_method = aws_api_gateway_method.events_get_by_id.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.events_get_by_id_lambda_arn
}

resource "aws_api_gateway_integration" "events_put" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.events_id.id
  http_method = aws_api_gateway_method.events_put.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.events_put_lambda_arn
}

resource "aws_api_gateway_integration" "events_delete" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.events_id.id
  http_method = aws_api_gateway_method.events_delete.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.events_delete_lambda_arn
}

# Competitions Resource
resource "aws_api_gateway_resource" "competitions" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "competitions"
}

resource "aws_api_gateway_resource" "competitions_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.competitions.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "competitions_register" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.competitions_id.id
  path_part   = "register"
}

resource "aws_api_gateway_resource" "competitions_results" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.competitions_id.id
  path_part   = "results"
}

# Competitions Methods
resource "aws_api_gateway_method" "competitions_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.competitions.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "competitions_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.competitions.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "competitions_get_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.competitions_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "competitions_register" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.competitions_register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "competitions_results" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.competitions_results.id
  http_method   = "GET"
  authorization = "NONE"
}

# Competitions Integrations
resource "aws_api_gateway_integration" "competitions_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.competitions.id
  http_method = aws_api_gateway_method.competitions_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.competitions_get_lambda_arn
}

resource "aws_api_gateway_integration" "competitions_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.competitions.id
  http_method = aws_api_gateway_method.competitions_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.competitions_post_lambda_arn
}

resource "aws_api_gateway_integration" "competitions_get_by_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.competitions_id.id
  http_method = aws_api_gateway_method.competitions_get_by_id.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.competitions_get_by_id_lambda_arn
}

resource "aws_api_gateway_integration" "competitions_register" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.competitions_register.id
  http_method = aws_api_gateway_method.competitions_register.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.competitions_register_lambda_arn
}

resource "aws_api_gateway_integration" "competitions_results" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.competitions_results.id
  http_method = aws_api_gateway_method.competitions_results.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.competitions_results_lambda_arn
}

# Volunteers Resource
resource "aws_api_gateway_resource" "volunteers" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "volunteers"
}

resource "aws_api_gateway_resource" "volunteers_join" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.volunteers.id
  path_part   = "join"
}

resource "aws_api_gateway_resource" "volunteers_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.volunteers.id
  path_part   = "{id}"
}

# Volunteers Methods
resource "aws_api_gateway_method" "volunteers_join" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.volunteers_join.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "volunteers_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.volunteers.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "volunteers_put" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.volunteers_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

# Volunteers Integrations
resource "aws_api_gateway_integration" "volunteers_join" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.volunteers_join.id
  http_method = aws_api_gateway_method.volunteers_join.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.volunteers_join_lambda_arn
}

resource "aws_api_gateway_integration" "volunteers_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.volunteers.id
  http_method = aws_api_gateway_method.volunteers_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.volunteers_get_lambda_arn
}

resource "aws_api_gateway_integration" "volunteers_put" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.volunteers_id.id
  http_method = aws_api_gateway_method.volunteers_put.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.volunteers_put_lambda_arn
}

# Suggestions Resource
resource "aws_api_gateway_resource" "suggestions" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "suggestions"
}

# Suggestions Methods
resource "aws_api_gateway_method" "suggestions_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.suggestions.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "suggestions_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.suggestions.id
  http_method   = "GET"
  authorization = "NONE"
}

# Suggestions Integrations
resource "aws_api_gateway_integration" "suggestions_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.suggestions.id
  http_method = aws_api_gateway_method.suggestions_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.suggestions_post_lambda_arn
}

resource "aws_api_gateway_integration" "suggestions_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.suggestions.id
  http_method = aws_api_gateway_method.suggestions_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.suggestions_get_lambda_arn
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "events_get" {
  statement_id  = "AllowExecutionFromAPIGateway-events-get"
  action        = "lambda:InvokeFunction"
  function_name = var.events_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "events_post" {
  statement_id  = "AllowExecutionFromAPIGateway-events-post"
  action        = "lambda:InvokeFunction"
  function_name = var.events_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "events_get_by_id" {
  statement_id  = "AllowExecutionFromAPIGateway-events-get-by-id"
  action        = "lambda:InvokeFunction"
  function_name = var.events_get_by_id_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "events_put" {
  statement_id  = "AllowExecutionFromAPIGateway-events-put"
  action        = "lambda:InvokeFunction"
  function_name = var.events_put_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "events_delete" {
  statement_id  = "AllowExecutionFromAPIGateway-events-delete"
  action        = "lambda:InvokeFunction"
  function_name = var.events_delete_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "competitions_get" {
  statement_id  = "AllowExecutionFromAPIGateway-competitions-get"
  action        = "lambda:InvokeFunction"
  function_name = var.competitions_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "competitions_post" {
  statement_id  = "AllowExecutionFromAPIGateway-competitions-post"
  action        = "lambda:InvokeFunction"
  function_name = var.competitions_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "competitions_get_by_id" {
  statement_id  = "AllowExecutionFromAPIGateway-competitions-get-by-id"
  action        = "lambda:InvokeFunction"
  function_name = var.competitions_get_by_id_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "competitions_register" {
  statement_id  = "AllowExecutionFromAPIGateway-competitions-register"
  action        = "lambda:InvokeFunction"
  function_name = var.competitions_register_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "competitions_results" {
  statement_id  = "AllowExecutionFromAPIGateway-competitions-results"
  action        = "lambda:InvokeFunction"
  function_name = var.competitions_results_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "volunteers_join" {
  statement_id  = "AllowExecutionFromAPIGateway-volunteers-join"
  action        = "lambda:InvokeFunction"
  function_name = var.volunteers_join_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "volunteers_get" {
  statement_id  = "AllowExecutionFromAPIGateway-volunteers-get"
  action        = "lambda:InvokeFunction"
  function_name = var.volunteers_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "volunteers_put" {
  statement_id  = "AllowExecutionFromAPIGateway-volunteers-put"
  action        = "lambda:InvokeFunction"
  function_name = var.volunteers_put_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "suggestions_post" {
  statement_id  = "AllowExecutionFromAPIGateway-suggestions-post"
  action        = "lambda:InvokeFunction"
  function_name = var.suggestions_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "suggestions_get" {
  statement_id  = "AllowExecutionFromAPIGateway-suggestions-get"
  action        = "lambda:InvokeFunction"
  function_name = var.suggestions_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "efy_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.events_get,
    aws_api_gateway_integration.events_post,
    aws_api_gateway_integration.events_get_by_id,
    aws_api_gateway_integration.events_put,
    aws_api_gateway_integration.events_delete,
    aws_api_gateway_integration.competitions_get,
    aws_api_gateway_integration.competitions_post,
    aws_api_gateway_integration.competitions_get_by_id,
    aws_api_gateway_integration.competitions_register,
    aws_api_gateway_integration.competitions_results,
    aws_api_gateway_integration.volunteers_join,
    aws_api_gateway_integration.volunteers_get,
    aws_api_gateway_integration.volunteers_put,
    aws_api_gateway_integration.suggestions_post,
    aws_api_gateway_integration.suggestions_get
  ]

  rest_api_id = aws_api_gateway_rest_api.efy_api.id
}

# API Gateway stage
resource "aws_api_gateway_stage" "efy_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  deployment_id = aws_api_gateway_deployment.efy_api_deployment.id
  stage_name    = "default"
}