# Cognito User Pool
resource "aws_cognito_user_pool" "efy_user_pool" {
  name = var.user_pool_name

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "role"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "organization"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Username configuration
  username_attributes = ["email"]

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Tags
  tags = var.tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "efy_user_pool_client" {
  name            = "${var.user_pool_name}-client"
  user_pool_id    = aws_cognito_user_pool.efy_user_pool.id
  generate_secret = false

  # Allowed OAuth flows
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # Callback URLs (to be updated with frontend URLs)
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Token validity
  access_token_validity  = 60 # 1 hour
  id_token_validity      = 60 # 1 hour
  refresh_token_validity = 30 # 30 days

  # Token validity units
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Read and write attributes
  read_attributes = [
    "email",
    "phone_number",
    "custom:role",
    "custom:organization"
  ]

  write_attributes = [
    "email",
    "phone_number",
    "custom:role",
    "custom:organization"
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "efy_user_pool_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.efy_user_pool.id
}

# IAM roles for each user group
resource "aws_iam_role" "student_role" {
  name = "${var.environment}-cognito-student-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "teacher_role" {
  name = "${var.environment}-cognito-teacher-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "volunteer_role" {
  name = "${var.environment}-cognito-volunteer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "admin_role" {
  name = "${var.environment}-cognito-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM role for authenticated users (default)
resource "aws_iam_role" "cognito_authenticated_role" {
  name = var.cognito_authenticated_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM role for unauthenticated users
resource "aws_iam_role" "cognito_unauthenticated_role" {
  name = var.cognito_unauthenticated_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.efy_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Basic IAM policies for roles (will be expanded based on permission matrix)
resource "aws_iam_role_policy" "student_policy" {
  name = "${var.environment}-student-policy"
  role = aws_iam_role.student_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/events",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/competitions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/courses",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/registrations",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/registrations",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/messages",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/messages",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/volunteers/apply",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/payments/create-order"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "teacher_policy" {
  name = "${var.environment}-teacher-policy"
  role = aws_iam_role.teacher_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/events",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/competitions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/courses",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/courses",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/PUT/courses/*",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/registrations",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/messages",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/messages"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "volunteer_policy" {
  name = "${var.environment}-volunteer-policy"
  role = aws_iam_role.volunteer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/events",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/competitions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/courses",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/registrations",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/registrations",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/suggestions",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/messages",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/messages",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/volunteers",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/PUT/volunteers/*",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/volunteers/tasks",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/PUT/volunteers/tasks/*",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/GET/volunteers/applications",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/volunteers/apply",
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/POST/payments/create-order"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "${var.environment}-admin-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = [
          "arn:aws:execute-api:${var.aws_region}:${var.account_id}:*/*/*"
        ]
      }
    ]
  })
}

# Cognito User Pool Groups
resource "aws_cognito_user_group" "student_group" {
  name         = "student"
  user_pool_id = aws_cognito_user_pool.efy_user_pool.id
  description  = "Student users with limited access"
  role_arn     = aws_iam_role.student_role.arn
  precedence   = 40
}

resource "aws_cognito_user_group" "teacher_group" {
  name         = "teacher"
  user_pool_id = aws_cognito_user_pool.efy_user_pool.id
  description  = "Teacher users with course management access"
  role_arn     = aws_iam_role.teacher_role.arn
  precedence   = 30
}

resource "aws_cognito_user_group" "volunteer_group" {
  name         = "volunteer"
  user_pool_id = aws_cognito_user_pool.efy_user_pool.id
  description  = "Volunteer users with task management access"
  role_arn     = aws_iam_role.volunteer_role.arn
  precedence   = 20
}

resource "aws_cognito_user_group" "admin_group" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.efy_user_pool.id
  description  = "Administrator users with full access"
  role_arn     = aws_iam_role.admin_role.arn
  precedence   = 10
}

# Cognito Identity Pool
resource "aws_cognito_identity_pool" "efy_identity_pool" {
  identity_pool_name               = var.identity_pool_name
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.efy_user_pool_client.id
    provider_name           = aws_cognito_user_pool.efy_user_pool.endpoint
    server_side_token_check = false
  }

  tags = var.tags
}

# Identity Pool Role Attachment
resource "aws_cognito_identity_pool_roles_attachment" "efy_identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.efy_identity_pool.id

  roles = {
    "authenticated"   = aws_iam_role.cognito_authenticated_role.arn
    "unauthenticated" = aws_iam_role.cognito_unauthenticated_role.arn
  }

  role_mapping {
    identity_provider         = "${aws_cognito_user_pool.efy_user_pool.endpoint}:${aws_cognito_user_pool_client.efy_user_pool_client.id}"
    ambiguous_role_resolution = "AuthenticatedRole"
    type                      = "Rules"

    mapping_rule {
      claim      = "cognito:groups"
      match_type = "Contains"
      value      = "admin"
      role_arn   = aws_iam_role.admin_role.arn
    }

    mapping_rule {
      claim      = "cognito:groups"
      match_type = "Contains"
      value      = "teacher"
      role_arn   = aws_iam_role.teacher_role.arn
    }

    mapping_rule {
      claim      = "cognito:groups"
      match_type = "Contains"
      value      = "volunteer"
      role_arn   = aws_iam_role.volunteer_role.arn
    }

    mapping_rule {
      claim      = "cognito:groups"
      match_type = "Contains"
      value      = "student"
      role_arn   = aws_iam_role.student_role.arn
    }
  }
}
