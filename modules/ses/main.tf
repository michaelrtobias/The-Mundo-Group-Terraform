resource "aws_ses_domain_mail_from" "southwestwatches" {
  domain           = aws_ses_domain_identity.southwestwatches.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.southwestwatches.domain}"
}
resource "aws_ses_domain_identity" "southwestwatches" {
  domain = "southwestwatches.com"
}
resource "aws_route53_record" "send_email_ses_domain_mail_from_mx" {
  zone_id = var.southwestwatches_zone.id
  name    = aws_ses_domain_mail_from.southwestwatches.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.us-east-1.amazonses.com"]
}
resource "aws_route53_record" "send_email_ses_domain_mail_from_txt" {
  zone_id = var.southwestwatches_zone.id
  name    = aws_ses_domain_mail_from.southwestwatches.mail_from_domain
  type    = "TXT"
  records = ["v=spf1 include:amazonses.com -all"]
  ttl     = 600
}
