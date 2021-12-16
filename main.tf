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


resource "aws_s3_bucket" "themundogroup_com" {
  bucket = "themundogroup.com"
  acl    = "public-read"
  versioning {
    enabled = true
  }
  website {
    index_document = "index.html"
    error_document = "index.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }
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

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
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
}

