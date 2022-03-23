resource "aws_api_gateway_rest_api" "the_mundo_group_api" {
  name = "mundo-group-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "the_mundo_group" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "the_mundo_group" {
  deployment_id = aws_api_gateway_deployment.the_mundo_group.id
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  stage_name    = "dev"
}

resource "aws_api_gateway_stage" "the_mundo_group_prod" {
  deployment_id = aws_api_gateway_deployment.the_mundo_group.id
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  stage_name    = "prod"
}

resource "aws_api_gateway_rest_api_policy" "the_mundo_group" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "assumerole",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*"
    }
  ]
}
EOF
}

resource "aws_api_gateway_resource" "wishlist" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  parent_id   = aws_api_gateway_rest_api.the_mundo_group_api.root_resource_id
  path_part   = "wishlist"
}

resource "aws_api_gateway_method" "wishlist" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.wishlist.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_lead_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.wishlist.id
  http_method             = aws_api_gateway_method.wishlist.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.create_lead_invoke_arn
}

resource "aws_api_gateway_resource" "images" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  parent_id   = aws_api_gateway_rest_api.the_mundo_group_api.root_resource_id
  path_part   = "images"
}


resource "aws_api_gateway_method" "images" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.images.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_image_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.images.id
  http_method             = aws_api_gateway_method.images.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.upload_image_invoke_arn
}

resource "aws_lambda_permission" "create_lambda" {
  statement_id  = "AllowTMGAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.create_lead_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "upload_image_lambda" {
  statement_id  = "AllowTMGUploadImageAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_image_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}
