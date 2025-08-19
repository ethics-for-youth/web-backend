# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = var.tags
}
