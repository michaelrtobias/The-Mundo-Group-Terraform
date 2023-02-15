resource "aws_route53_record" "admin_cognito" {
  name    = aws_cognito_user_pool_domain.sww_pool.domain
  type    = "A"
  zone_id = var.southwestwatches_zone.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_cognito_user_pool_domain.sww_pool.cloudfront_distribution_arn
    # This zone_id is fixed
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_acm_certificate" "admin_cert" {
  domain_name               = "admin.southwestwatches.com"
  validation_method         = "DNS"
  subject_alternative_names = ["southwestwatches.com", "www.southwestwatches.com"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cognito_user_pool" "sww_pool" {
  name = "southwestwatches-login"
}

resource "aws_cognito_user_pool_domain" "sww_pool" {
  domain          = "admin.southwestwatches.com"
  certificate_arn = aws_acm_certificate.admin_cert.arn

  user_pool_id = aws_cognito_user_pool.sww_pool.id
}

resource "aws_cognito_user_pool_client" "sww_cognito_ui" {
  name                                 = "sww-cognito-ui"
  user_pool_id                         = aws_cognito_user_pool.sww_pool.id
  callback_urls                        = ["https://southwestwatches.com"]
  logout_urls                          = ["https://southwestwatches.com"]
  default_redirect_uri                 = "https://southwestwatches.com"
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin", "email", "openid", "phone"]
}
