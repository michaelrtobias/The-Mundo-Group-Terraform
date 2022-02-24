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

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront distrobution for themundogroup.com"
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


# CI/CD for The Mundo Group UI

resource "aws_codepipeline" "codepipeline" {
  name     = "the-mundo-group-ui"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.themundogroup-frontend-pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn        = "${aws_codestarconnections_connection.github.arn}"
        FullRepositoryId     = "michaelrtobias/the-mundo-group-ui"
        BranchName           = "master"
        OutputArtifactFormat = "CODE_ZIP"

      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "mundo-group-ui"
      }
    }
  }


}



resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "themundogroup-frontend-pipeline" {
  bucket = "themundogroup-frontend-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "frontend-pipeline-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "frontend_codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject",
        "s3:ListObjects",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.themundogroup-frontend-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-frontend-pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${aws_codestarconnections_connection.github.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# CodeBuild for The Mundo Group UI

resource "aws_s3_bucket" "mundo_group_code_build_ui" {
  bucket = "mundo-group-code-build-ui"
  acl    = "private"
}

resource "aws_iam_role" "code_build_ui_role" {
  name = "code_build_ui_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "code_build_ui_role_policy" {
  role = aws_iam_role.code_build_ui_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:network-interface/*"
      ],
      "Condition": {
        "StringLike": {
          "ec2:Subnet": "*",
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
     {
      "Effect": "Allow",
      "Action": [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
      ],
      "Resource": [
          "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "${aws_s3_bucket.mundo_group_code_build_ui.arn}",
        "${aws_s3_bucket.mundo_group_code_build_ui.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListObjects",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.themundogroup-frontend-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-frontend-pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListObjects",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.themundogroup_com.arn}",
        "${aws_s3_bucket.themundogroup_com.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "s3-object-lambda:*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "mundo_group_ui_project" {
  name           = "mundo-group-ui"
  description    = "mundo-group-ui codebuild project"
  build_timeout  = "5"
  service_role   = aws_iam_role.code_build_ui_role.arn
  source_version = "master"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.mundo_group_code_build_ui.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-mundo-group-ui-group"
      stream_name = "codebuild-mundo-group-ui-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.mundo_group_code_build_ui.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 0
  }

  tags = {
    Environment = "prod"
  }
}

module "lambdas" {
  source                                 = "./modules/lambda"
  aws_codestarconnections_connection_arn = aws_codestarconnections_connection.github.arn
  send_email_queue                       = module.sqs.send_email_queue
}
# module "CICD" {
#   source = "./modules/lambda"
#   themundogroup_com_bucket_arn = aws_s3_bucket.themundogroup_com.arn
# }


module "api_gateway" {
  source                  = "./modules/apigateway"
  create_lead_invoke_arn  = module.lambdas.create_lead_invoke_arn
  upload_image_invoke_arn = module.lambdas.upload_image_invoke_arn
  create_lead_arn         = module.lambdas.create_lead_arn
  upload_image_arn        = module.lambdas.upload_image_arn
  create_lead_lambda      = module.lambdas.create_lead_lambda
  upload_image_lambda     = module.lambdas.upload_image_lambda
}

module "sqs" {
  source            = "./modules/sqs"
  send_email_lambda = module.lambdas.send_email_lambda
}
