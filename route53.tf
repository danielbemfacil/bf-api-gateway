resource "aws_route53_record" "api_gateway_alias" {
  zone_id = "Z01724703N4P77X260KE9"  # Use o ID da sua zona existente
  name    = "api-${var.environment}.bemfacil.com.br"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain.cloudfront_zone_id
    evaluate_target_health = false
  }
}
