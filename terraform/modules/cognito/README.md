# Cognito Module

This Terraform module creates an Amazon Cognito setup for role-based authentication and authorization (RBAC) in the EFY serverless backend.

## Features

- **Cognito User Pool**: User registration, authentication, and profile management
- **Cognito Identity Pool**: AWS credentials for authenticated users
- **Role-Based Access Control**: Four user types with specific permissions
- **JWT Token Validation**: Secure API access with role-based authorization
- **User Groups**: student, teacher, volunteer, admin with IAM role mappings

## User Roles

### Student (Limited Access)
- Register for events and competitions
- View available courses
- Submit suggestions and messages
- View personal registrations
- Apply for volunteer positions
- Create payment orders

### Teacher (Course Management)
- All Student permissions
- Create and manage courses
- View all student registrations
- Update courses

### Volunteer (Event Support)
- All Student permissions
- View own volunteer data
- Manage assigned volunteer tasks
- View volunteer applications
- Update own volunteer information

### Admin (Full Access)
- Full access to all API endpoints
- Manage all events, competitions, courses
- Manage volunteers and registrations
- Access admin dashboard and analytics
- Process payment webhooks

## Resources Created

### Cognito Resources
- `aws_cognito_user_pool` - User authentication and management
- `aws_cognito_user_pool_client` - OAuth client configuration
- `aws_cognito_user_pool_domain` - Hosted UI domain
- `aws_cognito_user_pool_group` - Role-based groups (student, teacher, volunteer, admin)
- `aws_cognito_identity_pool` - AWS credentials for authenticated users
- `aws_cognito_identity_pool_roles_attachment` - Role mappings

### IAM Resources
- `aws_iam_role` - IAM roles for each user group + authenticated/unauthenticated
- `aws_iam_role_policy` - Permission policies for each role

## Usage

```hcl
module "cognito" {
  source = "./modules/cognito"

  # Required variables
  environment                        = "dev"
  user_pool_name                    = "efy-dev-user-pool"
  identity_pool_name                = "efy-dev-identity-pool"
  user_pool_domain                  = "efy-dev"
  cognito_authenticated_role_name   = "efy-dev-cognito-authenticated"
  cognito_unauthenticated_role_name = "efy-dev-cognito-unauthenticated"
  aws_region                        = "us-east-1"
  account_id                        = "123456789012"
  api_gateway_id                    = "abcd123456"

  # Optional variables
  callback_urls = ["https://example.com/callback"]
  logout_urls   = ["https://example.com/logout"]
  
  tags = {
    Environment = "dev"
    Project     = "efy"
  }
}
```

## Outputs

- `user_pool_id` - Cognito User Pool ID
- `user_pool_client_id` - User Pool Client ID
- `identity_pool_id` - Identity Pool ID
- `jwks_uri` - JWKS URI for JWT validation
- Role ARNs for all user groups

## Security Features

- **Password Policy**: Strong password requirements
- **Advanced Security**: Cognito advanced security mode enforced
- **Email Verification**: Auto-verified email addresses
- **Token Expiration**: Short-lived access tokens (1 hour)
- **Refresh Tokens**: 30-day refresh token validity
- **Role Mapping**: Dynamic role assignment based on Cognito groups

## Integration

This module is designed to work with:
- API Gateway Cognito Authorizer
- Lambda function middleware for JWT validation
- DynamoDB permission system
- Frontend authentication flows

## Custom Attributes

The User Pool includes custom attributes:
- `role` - User's primary role in the system
- `organization` - User's organizational affiliation
- Standard attributes: `email`, `phone_number`