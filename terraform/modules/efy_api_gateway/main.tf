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

resource "aws_api_gateway_resource" "volunteers_apply" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.volunteers.id
  path_part   = "apply"
}

resource "aws_api_gateway_resource" "volunteers_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.volunteers.id
  path_part   = "{id}"
}

# Volunteers Methods
resource "aws_api_gateway_method" "volunteers_apply" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.volunteers_apply.id
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
resource "aws_api_gateway_integration" "volunteers_apply" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.volunteers_apply.id
  http_method = aws_api_gateway_method.volunteers_apply.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.volunteers_apply_lambda_arn
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

resource "aws_lambda_permission" "volunteers_apply" {
  statement_id  = "AllowExecutionFromAPIGateway-volunteers-apply"
  action        = "lambda:InvokeFunction"
  function_name = var.volunteers_apply_lambda_function_name
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

# Courses Resource
resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "courses"
}

resource "aws_api_gateway_resource" "courses_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{id}"
}

# Courses Methods
resource "aws_api_gateway_method" "courses_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "courses_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_method" "courses_get_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.courses_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "courses_put" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.courses_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "courses_delete" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.courses_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}


# Courses Integrations
resource "aws_api_gateway_integration" "courses_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.courses_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.courses_get_lambda_arn
}

resource "aws_api_gateway_integration" "courses_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.courses_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.courses_post_lambda_arn
}

resource "aws_api_gateway_integration" "courses_get_by_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.courses_id.id
  http_method = aws_api_gateway_method.courses_get_by_id.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.courses_get_by_id_lambda_arn
}

resource "aws_api_gateway_integration" "courses_put" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.courses_id.id
  http_method = aws_api_gateway_method.courses_put.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.courses_put_lambda_arn
}

resource "aws_api_gateway_integration" "courses_delete" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.courses_id.id
  http_method = aws_api_gateway_method.courses_delete.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.courses_delete_lambda_arn
}

# Courses Lambda Permissions
resource "aws_lambda_permission" "courses_get" {
  statement_id  = "AllowExecutionFromAPIGateway-courses-get"
  action        = "lambda:InvokeFunction"
  function_name = var.courses_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "courses_post" {
  statement_id  = "AllowExecutionFromAPIGateway-courses-post"
  action        = "lambda:InvokeFunction"
  function_name = var.courses_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "courses_get_by_id" {
  statement_id  = "AllowExecutionFromAPIGateway-courses-get-by-id"
  action        = "lambda:InvokeFunction"
  function_name = var.courses_get_by_id_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "courses_put" {
  statement_id  = "AllowExecutionFromAPIGateway-courses-put"
  action        = "lambda:InvokeFunction"
  function_name = var.courses_put_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "courses_delete" {
  statement_id  = "AllowExecutionFromAPIGateway-courses-delete"
  action        = "lambda:InvokeFunction"
  function_name = var.courses_delete_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

# Registrations Resource
resource "aws_api_gateway_resource" "registrations" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "registrations"
}

resource "aws_api_gateway_resource" "registrations_id" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.registrations.id
  path_part   = "{id}"
}

# Registrations Methods
resource "aws_api_gateway_method" "registrations_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.registrations.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_method" "registrations_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.registrations.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "registrations_put" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.registrations_id.id
  http_method   = "PUT"
  authorization = "NONE"
}


# Registrations Integrations
resource "aws_api_gateway_integration" "registrations_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.registrations.id
  http_method = aws_api_gateway_method.registrations_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.registrations_post_lambda_arn
}

resource "aws_api_gateway_integration" "registrations_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.registrations.id
  http_method = aws_api_gateway_method.registrations_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.registrations_get_lambda_arn
}

resource "aws_api_gateway_integration" "registrations_put" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.registrations_id.id
  http_method = aws_api_gateway_method.registrations_put.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.registrations_put_lambda_arn
}

# Registrations Lambda Permissions
resource "aws_lambda_permission" "registrations_post" {
  statement_id  = "AllowExecutionFromAPIGateway-registrations-post"
  action        = "lambda:InvokeFunction"
  function_name = var.registrations_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "registrations_get" {
  statement_id  = "AllowExecutionFromAPIGateway-registrations-get"
  action        = "lambda:InvokeFunction"
  function_name = var.registrations_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "registrations_put" {
  statement_id  = "AllowExecutionFromAPIGateway-registrations-put"
  action        = "lambda:InvokeFunction"
  function_name = var.registrations_put_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

# Messages Resource
resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "messages"
}

# Messages Methods
resource "aws_api_gateway_method" "messages_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_method" "messages_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "GET"
  authorization = "NONE"
}

# Messages Integrations
resource "aws_api_gateway_integration" "messages_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.messages_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.messages_post_lambda_arn
}

resource "aws_api_gateway_integration" "messages_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.messages_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.messages_get_lambda_arn
}

# Messages Lambda Permissions
resource "aws_lambda_permission" "messages_post" {
  statement_id  = "AllowExecutionFromAPIGateway-messages-post"
  action        = "lambda:InvokeFunction"
  function_name = var.messages_post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "messages_get" {
  statement_id  = "AllowExecutionFromAPIGateway-messages-get"
  action        = "lambda:InvokeFunction"
  function_name = var.messages_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

# Admin Resource
resource "aws_api_gateway_resource" "admin" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "admin"
}

resource "aws_api_gateway_resource" "admin_stats" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.admin.id
  path_part   = "stats"
}

# Admin Stats Methods
resource "aws_api_gateway_method" "admin_stats_get" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.admin_stats.id
  http_method   = "GET"
  authorization = "NONE"
}

# Admin Stats Integrations
resource "aws_api_gateway_integration" "admin_stats_get" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.admin_stats.id
  http_method = aws_api_gateway_method.admin_stats_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.admin_stats_get_lambda_arn
}

# Admin Stats Lambda Permissions
resource "aws_lambda_permission" "admin_stats_get" {
  statement_id  = "AllowExecutionFromAPIGateway-admin-stats-get"
  action        = "lambda:InvokeFunction"
  function_name = var.admin_stats_get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

# Payments Resource
resource "aws_api_gateway_resource" "payments" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_rest_api.efy_api.root_resource_id
  path_part   = "payments"
}

resource "aws_api_gateway_resource" "payments_create_order" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.payments.id
  path_part   = "create-order"
}

resource "aws_api_gateway_resource" "payments_webhook" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  parent_id   = aws_api_gateway_resource.payments.id
  path_part   = "webhook"
}

# Payments Methods
resource "aws_api_gateway_method" "payments_create_order_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.payments_create_order.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "payments_webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.payments_webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

# Payments Integrations
resource "aws_api_gateway_integration" "payments_create_order_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.payments_create_order.id
  http_method = aws_api_gateway_method.payments_create_order_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.payments_create_order_lambda_arn
}

resource "aws_api_gateway_integration" "payments_webhook_post" {
  rest_api_id = aws_api_gateway_rest_api.efy_api.id
  resource_id = aws_api_gateway_resource.payments_webhook.id
  http_method = aws_api_gateway_method.payments_webhook_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.payments_webhook_lambda_arn
}

# Payments Lambda Permissions
resource "aws_lambda_permission" "payments_create_order_post" {
  statement_id  = "AllowExecutionFromAPIGateway-payments-create-order-post"
  action        = "lambda:InvokeFunction"
  function_name = var.payments_create_order_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.efy_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "payments_webhook_post" {
  statement_id  = "AllowExecutionFromAPIGateway-payments-webhook-post"
  action        = "lambda:InvokeFunction"
  function_name = var.payments_webhook_lambda_function_name
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
    aws_api_gateway_integration.volunteers_apply,
    aws_api_gateway_integration.volunteers_get,
    aws_api_gateway_integration.volunteers_put,
    aws_api_gateway_integration.suggestions_post,
    aws_api_gateway_integration.suggestions_get,
    aws_api_gateway_integration.courses_get,
    aws_api_gateway_integration.courses_post,
    aws_api_gateway_integration.courses_get_by_id,
    aws_api_gateway_integration.courses_put,
    aws_api_gateway_integration.courses_delete,
    aws_api_gateway_integration.registrations_post,
    aws_api_gateway_integration.registrations_get,
    aws_api_gateway_integration.registrations_put,
    aws_api_gateway_integration.messages_post,
    aws_api_gateway_integration.messages_get,
    aws_api_gateway_integration.admin_stats_get,
    aws_api_gateway_integration.payments_create_order_post,
    aws_api_gateway_integration.payments_webhook_post
  ]

  rest_api_id = aws_api_gateway_rest_api.efy_api.id

  # Force new deployment when API structure changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.efy_api.id,
      # Track all integration changes
      aws_api_gateway_integration.events_get.id,
      aws_api_gateway_integration.events_post.id,
      aws_api_gateway_integration.events_get_by_id.id,
      aws_api_gateway_integration.events_put.id,
      aws_api_gateway_integration.events_delete.id,
      aws_api_gateway_integration.competitions_get.id,
      aws_api_gateway_integration.competitions_post.id,
      aws_api_gateway_integration.competitions_get_by_id.id,
      aws_api_gateway_integration.competitions_register.id,
      aws_api_gateway_integration.competitions_results.id,
      aws_api_gateway_integration.volunteers_apply.id,
      aws_api_gateway_integration.volunteers_get.id,
      aws_api_gateway_integration.volunteers_put.id,
      aws_api_gateway_integration.suggestions_post.id,
      aws_api_gateway_integration.suggestions_get.id,
      aws_api_gateway_integration.courses_get.id,
      aws_api_gateway_integration.courses_post.id,
      aws_api_gateway_integration.courses_get_by_id.id,
      aws_api_gateway_integration.courses_put.id,
      aws_api_gateway_integration.courses_delete.id,
      aws_api_gateway_integration.registrations_post.id,
      aws_api_gateway_integration.registrations_get.id,
      aws_api_gateway_integration.registrations_put.id,
      aws_api_gateway_integration.messages_post.id,
      aws_api_gateway_integration.messages_get.id,
      aws_api_gateway_integration.admin_stats_get.id,
      aws_api_gateway_integration.payments_create_order_post.id,
      aws_api_gateway_integration.payments_webhook_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "efy_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  deployment_id = aws_api_gateway_deployment.efy_api_deployment.id
  stage_name    = "api"
}
