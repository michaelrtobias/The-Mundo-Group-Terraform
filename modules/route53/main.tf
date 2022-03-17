resource "aws_route53_zone" "southwestwatches" {
  name = "southwestwatches.com"
}
resource "aws_route53_record" "southwestwatches_com" {
  zone_id = aws_route53_zone.southwestwatches.zone_id
  name    = "southwestwatches.com"
  type    = "A"

  alias {
    name                   = var.sww_cloudfront_distribution.domain_name
    zone_id                = var.sww_cloudfront_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "www_southwestwatches_com" {
  zone_id = aws_route53_zone.southwestwatches.zone_id
  name    = "www.southwestwatches.com"
  type    = "A"

  alias {
    name                   = var.sww_cloudfront_distribution.domain_name
    zone_id                = var.sww_cloudfront_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
