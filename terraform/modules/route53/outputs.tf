output "hosted_zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  description = "The name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "The domain name"
  value       = aws_route53_zone.main.name
}
