# Automatically create zip file from source directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "./builds/${var.function_name}.zip"
  
  # This ensures Terraform detects code changes
  excludes = ["*.zip"]
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler
  runtime       = var.runtime
  
  # This hash ensures function updates when code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  layers = var.layers
  
  environment {
    variables = var.environment_variables
  }
  
  tags = var.tags
  
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    data.archive_file.lambda_zip
  ]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}
