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

resource "aws_s3_bucket" "sww_code_build_ui" {
  bucket = "sww-code-build-ui"
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
        "${aws_s3_bucket.sww_code_build_ui.arn}",
        "${aws_s3_bucket.sww_code_build_ui.arn}/*"
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
        "${module.frontend.southwestwatches_com_bucket.arn}",
        "${module.frontend.southwestwatches_com_bucket.arn}/*"
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
    location = aws_s3_bucket.sww_code_build_ui.bucket
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
      location = "${aws_s3_bucket.sww_code_build_ui.id}/build-log"
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

module "route53" {
  source                      = "./modules/route53"
  sww_cloudfront_distribution = module.frontend.sww_cloudfront_distribution
}

module "frontend" {
  source = "./modules/frontend"
}
