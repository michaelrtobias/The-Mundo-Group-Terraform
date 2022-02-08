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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "send_email_lambda_policy_attachment" {
  role       = aws_iam_role.send_email_lambda_role.name
  policy_arn = aws_iam_policy.send_email_lambda_policy.arn
}
resource "aws_lambda_function" "send_email_lambda" {
  filename      = "send_email_lambda.zip"
  function_name = "send-email"
  role          = aws_iam_role.send_email_lambda_role.arn
  handler       = "index.js"
  runtime = "nodejs14.x"
}

resource "aws_s3_bucket" "tmg_send_email_src" {
  bucket = "send-email-src"
  acl    = "private"
  tags = {
    Name        = "Send Email Source Code"
  }
}