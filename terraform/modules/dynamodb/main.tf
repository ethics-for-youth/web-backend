# Events Table
resource "aws_dynamodb_table" "events" {
  name         = var.events_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Competitions Table
resource "aws_dynamodb_table" "competitions" {
  name         = var.competitions_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Volunteers Table
resource "aws_dynamodb_table" "volunteers" {
  name         = var.volunteers_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Suggestions Table
resource "aws_dynamodb_table" "suggestions" {
  name         = var.suggestions_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Courses Table
resource "aws_dynamodb_table" "courses" {
  name         = var.courses_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Registrations Table
resource "aws_dynamodb_table" "registrations" {
  name         = var.registrations_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Messages Table
resource "aws_dynamodb_table" "messages" {
  name         = var.messages_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# Payments Table
resource "aws_dynamodb_table" "payments" {
  name         = var.payments_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"
  range_key    = "paymentId"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "paymentId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # Global Secondary Index for querying by payment status
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by payment ID
  global_secondary_index {
    name            = "PaymentIndex"
    hash_key        = "paymentId"
    projection_type = "ALL"
  }

  tags = var.tags
}

# Duas Table
resource "aws_dynamodb_table" "duas" {
  name         = var.duas_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "week"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    projection_type = "ALL"
  }
  # Global Secondary Index for querying by week
  global_secondary_index {
    name            = "WeekIndex"
    hash_key        = "week"
    projection_type = "ALL"
  }

  tags = var.tags
}

# Output for Duas Table
output "duas_table_name" {
  value = aws_dynamodb_table.duas.name
}

output "duas_table_arn" {
  value = aws_dynamodb_table.duas.arn
}