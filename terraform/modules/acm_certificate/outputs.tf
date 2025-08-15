output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_status" {
  description = "The status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "domain_name" {
  description = "The domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}