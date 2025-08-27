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

# Permissions Table for RBAC system
resource "aws_dynamodb_table" "permissions" {
  name         = var.permissions_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "resource"
    type = "S"
  }

  attribute {
    name = "role"
    type = "S"
  }

  # Global Secondary Index for querying by resource
  global_secondary_index {
    name            = "ResourceIndex"
    hash_key        = "resource"
    range_key       = "role"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by role
  global_secondary_index {
    name            = "RoleIndex"
    hash_key        = "role"
    range_key       = "resource"
    projection_type = "ALL"
  }

  tags = var.tags
}

# Users Table for storing Cognito user mappings and metadata
resource "aws_dynamodb_table" "users" {
  name         = var.users_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "role"
    type = "S"
  }

  # Global Secondary Index for querying by email
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by role
  global_secondary_index {
    name            = "RoleIndex"
    hash_key        = "role"
    projection_type = "ALL"
  }

  tags = var.tags
}

# Volunteer Tasks Table
resource "aws_dynamodb_table" "volunteer_tasks" {
  name         = var.volunteer_tasks_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "volunteerId"
    type = "S"
  }

  attribute {
    name = "eventId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global Secondary Index for querying by volunteer
  global_secondary_index {
    name            = "VolunteerIndex"
    hash_key        = "volunteerId"
    range_key       = "status"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by event
  global_secondary_index {
    name            = "EventIndex"
    hash_key        = "eventId"
    range_key       = "status"
    projection_type = "ALL"
  }

  tags = var.tags
}

# Volunteer Applications Table
resource "aws_dynamodb_table" "volunteer_applications" {
  name         = var.volunteer_applications_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "volunteerId"
    type = "S"
  }

  attribute {
    name = "eventId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global Secondary Index for querying by volunteer
  global_secondary_index {
    name            = "VolunteerIndex"
    hash_key        = "volunteerId"
    range_key       = "status"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by event
  global_secondary_index {
    name            = "EventIndex"
    hash_key        = "eventId"
    range_key       = "status"
    projection_type = "ALL"
  }

  tags = var.tags
}
