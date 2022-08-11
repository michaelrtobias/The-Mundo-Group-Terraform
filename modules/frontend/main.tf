resource "aws_s3_bucket" "www_southwestwatches_com" {
  bucket = "www.southwestwatches.com"
  versioning {
    enabled = true
  }

}

resource "aws_s3_bucket_acl" "www_southwestwatches_com" {
  bucket = aws_s3_bucket.www_southwestwatches_com.id
  acl    = "public-read"
}

resource "aws_s3_bucket_versioning" "www_southwestwatches_com" {
  bucket = aws_s3_bucket.www_southwestwatches_com.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "www_southwestwatches_com" {
  bucket = aws_s3_bucket.www_southwestwatches_com.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket" "media_bucket" {
  bucket = "southwest-watches-media"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Southwest Watches Media Bucket"
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

resource "aws_s3_bucket" "southwestwatches" {
  bucket = "southwestwatches"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "southwest watches media upload bucket"
    Environment = "Dev"
  }
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "southwestwatches_bucket_policy" {
  bucket = aws_s3_bucket.southwestwatches.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AddPerm",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["s3:GetObject", "s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject"],
        "Resource" : "arn:aws:s3:::southwestwatches/*"
      }
    ]
  })
}



# frontend - Cloudfront, SSL Certificate, Cloudfront Logs, Website Bucket

locals {
  s3_origin_id = "southwestwatches_com_origin_id"
}

resource "aws_s3_bucket" "southwestwatches_com" {
  bucket = "southwestwatches.com"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  website {
    index_document = "index.html"
    error_document = "index.html"
  }

}

resource "aws_s3_bucket_acl" "southwestwatches_com" {
  bucket = aws_s3_bucket.southwestwatches_com.id
  acl    = "public-read"
}


resource "aws_cloudfront_origin_access_identity" "s3-access-origin" {
  comment = "origin access identity resource for southwestwatches.com distrobution"
}




resource "aws_acm_certificate" "cert" {
  domain_name               = "southwestwatches.com"
  validation_method         = "DNS"
  subject_alternative_names = ["www.southwestwatches.com"]
  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_s3_bucket" "sww_cloudwatch_distribution_logs" {
  bucket = "southwestwatches-cloudwatch-logs"
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

resource "aws_cloudfront_distribution" "sww_distribution" {
  origin {
    domain_name = aws_s3_bucket.southwestwatches_com.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3-access-origin.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront distrobution for southwestwatches.com"
  default_root_object = "index.html"
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
    bucket          = aws_s3_bucket.sww_cloudwatch_distribution_logs.bucket_domain_name
    prefix          = "southwestwatches-website"
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
  aliases = ["www.southwestwatches.com", "southwestwatches.com"]


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


