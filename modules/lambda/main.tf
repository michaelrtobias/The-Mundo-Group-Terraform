# send email infrastructure

resource "aws_iam_role" "send_email_lambda_role" {
  name = "send_email"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "send_email_lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "IAM policy for send email lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${var.send_email_queue.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send_email_lambda_policy_attachment" {
  role       = aws_iam_role.send_email_lambda_role.name
  policy_arn = aws_iam_policy.send_email_lambda_policy.arn
}

resource "aws_s3_bucket" "mundo_group_lambda_code" {
  bucket = "mundo-group-lambda-code"
  acl    = "private"
  tags = {
    Name = "Lambda Code"
  }
}
data "aws_s3_bucket_object" "send_email_code" {
  bucket = aws_s3_bucket.mundo_group_lambda_code.bucket
  key    = "lambdas/sendEmail.zip"
}
resource "aws_lambda_function" "send_email_lambda" {
  function_name     = "send-email"
  role              = aws_iam_role.send_email_lambda_role.arn
  handler           = "src/index.handler"
  runtime           = "nodejs14.x"
  s3_bucket         = aws_s3_bucket.mundo_group_lambda_code.bucket
  s3_key            = data.aws_s3_bucket_object.send_email_code.key
  s3_object_version = data.aws_s3_bucket_object.send_email_code.version_id

}


# CI/CD for The Mundo Group Lambda sendEmail

resource "aws_codepipeline" "codepipeline_sendEmail_Lambda" {
  name     = "the-mundo-group-lambda-sendEmail"
  role_arn = aws_iam_role.codepipeline_role_sendEmail.arn

  artifact_store {
    location = aws_s3_bucket.themundogroup-lambda-sendEmail-pipeline.bucket
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
        ConnectionArn        = var.aws_codestarconnections_connection_arn
        FullRepositoryId     = "michaelrtobias/tmg-send-email"
        BranchName           = "main"
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
        ProjectName = "mundo-group-lambda-sendEmail"
      }
    }
  }


}


resource "aws_s3_bucket" "themundogroup-lambda-sendEmail-pipeline" {
  bucket = "themundogroup-lambda-send-email-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role_sendEmail" {
  name               = "lambda-sendEmail-pipeline-role"
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

resource "aws_iam_role_policy" "codepipeline_policy_sendEmail" {
  name = "lambda_sendEmail_codepipeline_policy"
  role = aws_iam_role.codepipeline_role_sendEmail.id

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
        "${aws_s3_bucket.themundogroup-lambda-sendEmail-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-sendEmail-pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${var.aws_codestarconnections_connection_arn}"
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


# CodeBuild for The Mundo Group send email lambda code

resource "aws_s3_bucket" "mundo_group_code_build_lambda_sendEmail" {
  bucket = "mundo-group-code-build-lambda-send-email"
  acl    = "private"
}

resource "aws_iam_role" "code_build_lambda_sendEmail_role" {
  name = "code_build_lambda_sendEmail_role"

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

resource "aws_iam_role_policy" "code_build_lambda_sendEmail_role_policy" {
  role = aws_iam_role.code_build_lambda_sendEmail_role.name

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
        "${aws_s3_bucket.mundo_group_code_build_lambda_sendEmail.arn}",
        "${aws_s3_bucket.mundo_group_code_build_lambda_sendEmail.arn}/*"
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
        "${aws_s3_bucket.themundogroup-lambda-sendEmail-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-sendEmail-pipeline.arn}/*",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Resource": [
        "${aws_lambda_function.send_email_lambda.arn}",
        "${aws_lambda_function.send_email_lambda.arn}/*"
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

resource "aws_codebuild_project" "mundo_group_lambda_sendEmail_project" {
  name           = "mundo-group-lambda-sendEmail"
  description    = "mundo-group-lambda-sendEmail codebuild project"
  build_timeout  = "5"
  service_role   = aws_iam_role.code_build_lambda_sendEmail_role.arn
  source_version = "master"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.mundo_group_code_build_lambda_sendEmail.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-mundo-group-lambda-sendEmail-group"
      stream_name = "codebuild-mundo-group-lambda-sendEmail-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.mundo_group_code_build_lambda_sendEmail.id}/build-log"
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



# create lead lambda infrastructure

data "aws_dynamodb_table" "leads_table" {
  name = "leads"
}

resource "aws_iam_role" "create_lead_lambda_role" {
  name = "create_lead"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "create_lead_lambda_policy" {
  name        = "create_lead_lambda_policy"
  path        = "/"
  description = "IAM policy for create lead lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
     "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": "${data.aws_dynamodb_table.leads_table.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "create_lead_lambda_policy_attachment" {
  role       = aws_iam_role.create_lead_lambda_role.name
  policy_arn = aws_iam_policy.create_lead_lambda_policy.arn
}

data "aws_s3_bucket_object" "create_lead_code" {
  bucket = aws_s3_bucket.mundo_group_lambda_code.bucket
  key    = "lambdas/createLead.zip"
}
resource "aws_lambda_function" "create_lead_lambda" {
  function_name     = "create-lead"
  role              = aws_iam_role.create_lead_lambda_role.arn
  handler           = "src/index.handler"
  runtime           = "nodejs14.x"
  s3_bucket         = aws_s3_bucket.mundo_group_lambda_code.bucket
  s3_key            = data.aws_s3_bucket_object.create_lead_code.key
  s3_object_version = data.aws_s3_bucket_object.create_lead_code.version_id
  environment {
    variables = {
      QUEUEURL = var.send_email_queue.url
    }
  }
}


# CI/CD for The Mundo Group Lambda createLead

resource "aws_codepipeline" "codepipeline_createLead_Lambda" {
  name     = "the-mundo-group-lambda-createLead"
  role_arn = aws_iam_role.codepipeline_role_createLead.arn

  artifact_store {
    location = aws_s3_bucket.themundogroup-lambda-createLead-pipeline.bucket
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
        ConnectionArn        = var.aws_codestarconnections_connection_arn
        FullRepositoryId     = "michaelrtobias/tmg-create-lead"
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
        ProjectName = "mundo-group-lambda-createLead"
      }
    }
  }


}


resource "aws_s3_bucket" "themundogroup-lambda-createLead-pipeline" {
  bucket = "themundogroup-lambda-create-lead-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role_createLead" {
  name               = "lambda-createLead-pipeline-role"
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

resource "aws_iam_role_policy" "codepipeline_policy_createLead" {
  name = "lambda_createLead_codepipeline_policy"
  role = aws_iam_role.codepipeline_role_createLead.id

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
        "${aws_s3_bucket.themundogroup-lambda-createLead-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-createLead-pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${var.aws_codestarconnections_connection_arn}"
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


# CodeBuild for The Mundo Group lambda code

resource "aws_s3_bucket" "mundo_group_code_build_lambda_createLead" {
  bucket = "mundo-group-code-build-lambda-create-lead"
  acl    = "private"
}

resource "aws_iam_role" "code_build_lambda_createLead_role" {
  name = "code_build_lambda_createLead_role"

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

resource "aws_iam_role_policy" "code_build_lambda_createLead_role_policy" {
  role = aws_iam_role.code_build_lambda_createLead_role.name

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
        "${aws_s3_bucket.mundo_group_code_build_lambda_createLead.arn}",
        "${aws_s3_bucket.mundo_group_code_build_lambda_createLead.arn}/*"
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
        "${aws_s3_bucket.themundogroup-lambda-createLead-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-createLead-pipeline.arn}/*",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Resource": [
        "${aws_lambda_function.create_lead_lambda.arn}",
        "${aws_lambda_function.create_lead_lambda.arn}/*"
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

resource "aws_codebuild_project" "mundo_group_lambda_createLead_project" {
  name           = "mundo-group-lambda-createLead"
  description    = "mundo-group-lambda-createLead codebuild project"
  build_timeout  = "5"
  service_role   = aws_iam_role.code_build_lambda_createLead_role.arn
  source_version = "master"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.mundo_group_code_build_lambda_createLead.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-mundo-group-lambda-createLead-group"
      stream_name = "codebuild-mundo-group-lambda-createLead-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.mundo_group_code_build_lambda_createLead.id}/build-log"
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





# upload image lambda infrastructure

resource "aws_iam_role" "upload_image_lambda_role" {
  name = "upload_image"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "upload_image_lambda_policy" {
  name        = "upload_image_lambda_policy"
  path        = "/"
  description = "IAM policy for upload image lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "upload_image_lambda_policy_attachment" {
  role       = aws_iam_role.upload_image_lambda_role.name
  policy_arn = aws_iam_policy.upload_image_lambda_policy.arn
}

data "aws_s3_bucket_object" "upload_image_code" {
  bucket = aws_s3_bucket.mundo_group_lambda_code.bucket
  key    = "lambdas/uploadImage.zip"
}
resource "aws_lambda_function" "upload_image_lambda" {
  function_name     = "upload-image"
  role              = aws_iam_role.upload_image_lambda_role.arn
  handler           = "src/index.handler"
  runtime           = "nodejs14.x"
  s3_bucket         = aws_s3_bucket.mundo_group_lambda_code.bucket
  s3_key            = data.aws_s3_bucket_object.upload_image_code.key
  s3_object_version = data.aws_s3_bucket_object.upload_image_code.version_id
  environment {
    variables = {
      BUCKET = "southwestwatches"
    }
  }
}


# CI/CD for The Mundo Group Lambda uploadImage

resource "aws_codepipeline" "codepipeline_uploadImage_Lambda" {
  name     = "the-mundo-group-lambda-uploadImage"
  role_arn = aws_iam_role.codepipeline_role_uploadImage.arn

  artifact_store {
    location = aws_s3_bucket.themundogroup-lambda-uploadImage-pipeline.bucket
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
        ConnectionArn        = var.aws_codestarconnections_connection_arn
        FullRepositoryId     = "michaelrtobias/tmg-upload-image"
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
        ProjectName = "mundo-group-lambda-uploadImage"
      }
    }
  }


}


resource "aws_s3_bucket" "themundogroup-lambda-uploadImage-pipeline" {
  bucket = "themundogroup-lambda-upload-image-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role_uploadImage" {
  name               = "lambda-uploadImage-pipeline-role"
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

resource "aws_iam_role_policy" "codepipeline_policy_uploadImage" {
  name = "lambda_uploadImage_codepipeline_policy"
  role = aws_iam_role.codepipeline_role_uploadImage.id

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
        "${aws_s3_bucket.themundogroup-lambda-uploadImage-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-uploadImage-pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": "${var.aws_codestarconnections_connection_arn}"
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


# CodeBuild for The Mundo Group lambda code

resource "aws_s3_bucket" "mundo_group_code_build_lambda_uploadImage" {
  bucket = "mundo-group-code-build-lambda-upload-image"
  acl    = "private"
}

resource "aws_iam_role" "code_build_lambda_uploadImage_role" {
  name = "code_build_lambda_uploadImage_role"

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

resource "aws_iam_role_policy" "code_build_lambda_uploadImage_role_policy" {
  role = aws_iam_role.code_build_lambda_uploadImage_role.name

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
        "${aws_s3_bucket.mundo_group_code_build_lambda_uploadImage.arn}",
        "${aws_s3_bucket.mundo_group_code_build_lambda_uploadImage.arn}/*"
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
        "${aws_s3_bucket.themundogroup-lambda-uploadImage-pipeline.arn}",
        "${aws_s3_bucket.themundogroup-lambda-uploadImage-pipeline.arn}/*",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}",
        "${aws_s3_bucket.mundo_group_lambda_code.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Resource": [
        "${aws_lambda_function.upload_image_lambda.arn}",
        "${aws_lambda_function.upload_image_lambda.arn}/*"
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

resource "aws_codebuild_project" "mundo_group_lambda_uploadImage_project" {
  name           = "mundo-group-lambda-uploadImage"
  description    = "mundo-group-lambda-uploadImage codebuild project"
  build_timeout  = "5"
  service_role   = aws_iam_role.code_build_lambda_uploadImage_role.arn
  source_version = "master"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.mundo_group_code_build_lambda_uploadImage.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-mundo-group-lambda-uploadImage-group"
      stream_name = "codebuild-mundo-group-lambda-uploadImage-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.mundo_group_code_build_lambda_uploadImage.id}/build-log"
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
