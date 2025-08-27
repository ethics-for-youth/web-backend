output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.efy_user_pool.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.efy_user_pool.arn
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.efy_user_pool_client.id
}

output "user_pool_client_secret" {
  description = "Secret of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.efy_user_pool_client.client_secret
  sensitive   = true
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.efy_user_pool.endpoint
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.efy_user_pool_domain.domain
}

output "identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.efy_identity_pool.id
}

output "authenticated_role_arn" {
  description = "ARN of the authenticated IAM role"
  value       = aws_iam_role.cognito_authenticated_role.arn
}

output "unauthenticated_role_arn" {
  description = "ARN of the unauthenticated IAM role"
  value       = aws_iam_role.cognito_unauthenticated_role.arn
}

output "student_role_arn" {
  description = "ARN of the student IAM role"
  value       = aws_iam_role.student_role.arn
}

output "teacher_role_arn" {
  description = "ARN of the teacher IAM role"
  value       = aws_iam_role.teacher_role.arn
}

output "volunteer_role_arn" {
  description = "ARN of the volunteer IAM role"
  value       = aws_iam_role.volunteer_role.arn
}

output "admin_role_arn" {
  description = "ARN of the admin IAM role"
  value       = aws_iam_role.admin_role.arn
}

output "user_groups" {
  description = "Map of user pool groups"
  value = {
    student   = aws_cognito_user_group.student_group.name
    teacher   = aws_cognito_user_group.teacher_group.name
    volunteer = aws_cognito_user_group.volunteer_group.name
    admin     = aws_cognito_user_group.admin_group.name
  }
}

output "jwks_uri" {
  description = "JWKS URI for JWT token validation"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.efy_user_pool.id}/.well-known/jwks.json"
}