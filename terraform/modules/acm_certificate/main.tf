terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Adjust version as needed
    }
  }
}

# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# Route 53 DNS validation records - use count with unique domains only
resource "aws_route53_record" "cert_validation" {
  count = length(local.unique_domains)

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.main.domain_validation_options)[count.index].resource_record_name
  records         = [tolist(aws_acm_certificate.main.domain_validation_options)[count.index].resource_record_value]
  ttl             = 60
  type            = tolist(aws_acm_certificate.main.domain_validation_options)[count.index].resource_record_type
  zone_id         = var.hosted_zone_id
}

# Local values to deduplicate domains
locals {
  # Remove duplicates between domain_name and subject_alternative_names
  unique_domains = distinct(concat([var.domain_name], var.subject_alternative_names))
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}