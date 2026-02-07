# Use pre-built lambda zip with reproducible timestamps
# The zip is created by build.sh script with SOURCE_DATE_EPOCH=1
# This ensures the hash only changes when actual content changes, not timestamps

locals {
  # Extract just the lambda function name from the full function name
  # e.g., "efy-dev-events-get" -> "events_get"
  # Remove the project name and environment prefix, then convert dashes to underscores
  function_without_prefix = regex("[^-]+-[^-]+-(.*)", var.function_name)[0]
  lambda_base_name        = replace(local.function_without_prefix, "-", "_")
  zip_path                = "${path.root}/builds/${local.lambda_base_name}.zip"
}

# Compute hash from the pre-built zip file
data "local_file" "lambda_zip" {
  filename = local.zip_path
}

resource "aws_lambda_function" "this" {
  filename      = local.zip_path
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout

  # Use filebase64sha256 to compute hash from the pre-built zip
  source_code_hash = filebase64sha256(local.zip_path)

  layers = var.layers

  environment {
    variables = var.environment_variables
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    data.local_file.lambda_zip
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

# DynamoDB permissions for the Lambda function
resource "aws_iam_role_policy" "lambda_dynamodb" {
  count = length(var.dynamodb_table_arns) > 0 ? 1 : 0
  name  = "${var.function_name}-dynamodb-policy"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchGetItem"
        ]
        Resource = var.dynamodb_table_arns
      }
    ]
  })
}

# S3 permissions for the Lambda function
resource "aws_iam_role_policy" "lambda_s3" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0
  name  = "${var.function_name}-s3-policy"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        )
      }
    ]
  })
}
