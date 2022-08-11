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

resource "aws_lambda_permission" "create_lambda" {
  statement_id  = "AllowTMGAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.create_lead_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
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


resource "aws_lambda_permission" "upload_image_lambda" {
  statement_id  = "AllowTMGUploadImageAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_image_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}


resource "aws_api_gateway_method" "delete_images" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.images.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_images_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.images.id
  http_method             = aws_api_gateway_method.delete_images.http_method
  integration_http_method = "DELETE"
  type                    = "AWS_PROXY"
  uri                     = var.delete_image_lambda.invoke_arn
}


resource "aws_lambda_permission" "delete_images_lambda" {
  statement_id  = "AllowTMGCreateInventoryAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.delete_image_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "delete_images_200" {
  rest_api_id         = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id         = aws_api_gateway_resource.images.id
  http_method         = aws_api_gateway_method.delete_images.http_method
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
  status_code = "200"
}
resource "aws_api_gateway_method_response" "delete_images_400" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.images.id
  http_method = aws_api_gateway_method.delete_images.http_method
  status_code = "400"
}



resource "aws_api_gateway_integration_response" "delete_images" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.images.id
  http_method = aws_api_gateway_method.delete_images.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
// inventory lambdas
resource "aws_api_gateway_resource" "inventory" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  parent_id   = aws_api_gateway_rest_api.the_mundo_group_api.root_resource_id
  path_part   = "inventory"
}
// create
resource "aws_api_gateway_method" "create_inventory" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.inventory.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_inventory_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.inventory.id
  http_method             = aws_api_gateway_method.create_inventory.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.inventory_lambdas["create-inventory"].invoke_arn
}

resource "aws_lambda_permission" "create_inventory_lambda" {
  statement_id  = "AllowTMGCreateInventoryAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.inventory_lambdas["create-inventory"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "create_inventory_200" {
  rest_api_id         = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id         = aws_api_gateway_resource.inventory.id
  http_method         = aws_api_gateway_method.create_inventory.http_method
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
  status_code = "200"
}
resource "aws_api_gateway_method_response" "create_inventory_400" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.create_inventory.http_method
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "create_inventory" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.create_inventory.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
// read
resource "aws_api_gateway_method" "read_inventory" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.inventory.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "read_inventory_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.inventory.id
  http_method             = aws_api_gateway_method.read_inventory.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = var.inventory_lambdas["read-inventory"].invoke_arn
}

resource "aws_lambda_permission" "read_inventory_lambda" {
  statement_id  = "AllowTMGReadInventoryAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.inventory_lambdas["read-inventory"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "read_inventory_200" {
  rest_api_id         = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id         = aws_api_gateway_resource.inventory.id
  http_method         = aws_api_gateway_method.read_inventory.http_method
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
  status_code = "200"
}
resource "aws_api_gateway_method_response" "read_inventory_400" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.read_inventory.http_method
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "read_inventory" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.read_inventory.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
// update
resource "aws_api_gateway_method" "update_inventory" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.inventory.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "update_inventory_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.inventory.id
  http_method             = aws_api_gateway_method.update_inventory.http_method
  integration_http_method = "PUT"
  type                    = "AWS_PROXY"
  uri                     = var.inventory_lambdas["update-inventory"].invoke_arn
}

resource "aws_lambda_permission" "update_inventory_lambda" {
  statement_id  = "AllowTMGUpdateInventoryAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.inventory_lambdas["update-inventory"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "update_inventory_200" {
  rest_api_id         = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id         = aws_api_gateway_resource.inventory.id
  http_method         = aws_api_gateway_method.update_inventory.http_method
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
  status_code = "200"
}
resource "aws_api_gateway_method_response" "update_inventory_400" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.update_inventory.http_method
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "update_inventory" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.update_inventory.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
// delete
resource "aws_api_gateway_method" "delete_inventory" {
  rest_api_id   = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id   = aws_api_gateway_resource.inventory.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_inventory_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id             = aws_api_gateway_resource.inventory.id
  http_method             = aws_api_gateway_method.delete_inventory.http_method
  integration_http_method = "DELETE"
  type                    = "AWS_PROXY"
  uri                     = var.inventory_lambdas["delete-inventory"].invoke_arn
}

resource "aws_lambda_permission" "delete_inventory_lambda" {
  statement_id  = "AllowTMGDeleteInventoryAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.inventory_lambdas["delete-inventory"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.the_mundo_group_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "delete_inventory_200" {
  rest_api_id         = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id         = aws_api_gateway_resource.inventory.id
  http_method         = aws_api_gateway_method.delete_inventory.http_method
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
  response_models = {
    "application/json" = "Empty"
  }
  status_code = "200"
}
resource "aws_api_gateway_method_response" "delete_inventory_400" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.delete_inventory.http_method
  status_code = "400"
}
resource "aws_api_gateway_integration_response" "delete_inventory" {
  rest_api_id = aws_api_gateway_rest_api.the_mundo_group_api.id
  resource_id = aws_api_gateway_resource.inventory.id
  http_method = aws_api_gateway_method.delete_inventory.http_method
  status_code = "200"

  response_templates = {
    "application/json" = ""
  }
}
