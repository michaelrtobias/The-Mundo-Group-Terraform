terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "mundo"
}



resource "aws_s3_bucket" "www_themundogroup_com" {
  bucket = "www.themundogroup.com"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  website {
    index_document = "index.html"
    error_document = "index.html"


  }
}

resource "aws_s3_bucket" "media_bucket" {
  bucket = "the-mundo-group-media"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Mundo Media Bucket"
    Environment = "Dev"
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "themundogroup" {
  bucket = "themundogroup"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Mundo media upload bucket"
    Environment = "Dev"
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "themundogroup_bucket_policy" {
  bucket = aws_s3_bucket.themundogroup.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AddPerm",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["s3:GetObject", "s3:PutObject", "s3:PutObjectAcl"],
        "Resource" : "arn:aws:s3:::themundogroup/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "themundogroup-api" {
  bucket = "themundogroup-api"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "The Mundo Group API Lambda Code bucket"
    Environment = "Dev"
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# frontend - Cloudfront, SSL Certificate, Cloudfront Logs, Website Bucket

locals {
  s3_origin_id = "themundogroup_com_origin_id"
}

resource "aws_s3_bucket" "themundogroup_com" {
  bucket = var.themundogroup_website_bucket_name
  acl    = "public-read"
  versioning {
    enabled = true
  }
  website {
    index_document = "index.html"
    error_document = "index.html"
#     routing_rules  = <<EOF
# [{
#     "Condition": {
#         "HttpErrorCodeReturnedEquals": "403"
#     },
#     "Redirect": {
#         "ReplaceKeyWith": "/index.html"
#     }
# },
# {
#     "Condition": {
#         "HttpErrorCodeReturnedEquals": "404"
#     },
#     "Redirect": {
#         "ReplaceKeyWith": "/index.html"
#     }
# }
# ]
# EOF
  }

}

resource "aws_s3_bucket_policy" "themundogroup_com_bucket_policy" {
  bucket = aws_s3_bucket.themundogroup_com.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AddPerm",
        "Effect" : "Allow",
        "Principal" : aws_cloudfront_origin_access_identity.s3-access-origin.iam_arn,
        "Action" : ["s3:GetObject*", "s3:GetBucket*", "s3:List*"],
        "Resource" : ["${aws_s3_bucket.themundogroup_com.arn}/*", aws_s3_bucket.themundogroup_com.arn]
      }
    ]
  })
}


resource "aws_acm_certificate" "cert" {
  domain_name               = var.themundogroup_website_bucket_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.themundogroup.com"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_origin_access_identity" "s3-access-origin" {
  comment = "origin access identity resource for themundogroup.com distrobution"
}

resource "aws_s3_bucket" "cloudwatch_distribution_logs" {
  bucket = "themundogroup-cloudwatch-logs"
  acl    = "log-delivery-write"
  versioning {
    enabled = true
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.themundogroup_com.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3-access-origin.cloudfront_access_identity_path
    }
  }

  enabled               = true
  is_ipv6_enabled       = true
  comment               = "Cloudfront distrobution for themundogroup.com"
  default_root_object   = "index.html"
  custom_error_response {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  custom_error_response {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudwatch_distribution_logs.bucket_domain_name
    prefix          = "themundogroup-website"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  aliases = ["www.themundogroup.com", "themundogroup.com"]


  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "UM"]
    }
  }


  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# route 53


resource "aws_route53_zone" "themundogroup_zone" {
  name = "themundogroup.com"
}

resource "aws_route53_record" "themundogroup_com" {
  zone_id = aws_route53_zone.themundogroup_zone.zone_id
  name    = "themundogroup.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "www_themundogroup_com" {
  zone_id = aws_route53_zone.themundogroup_zone.zone_id
  name    = "www.themundogroup.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

