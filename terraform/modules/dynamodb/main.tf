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
