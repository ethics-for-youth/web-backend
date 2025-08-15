output "main_record_fqdn" {
  description = "The FQDN of the main domain record"
  value       = aws_route53_record.main.fqdn
}

output "www_record_fqdn" {
  description = "The FQDN of the www subdomain record"
  value       = var.create_www_record ? aws_route53_record.www[0].fqdn : null
}