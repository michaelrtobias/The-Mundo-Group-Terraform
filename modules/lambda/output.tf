output "create_lead_invoke_arn" {
  value = aws_lambda_function.create_lead_lambda.invoke_arn
}

output "create_lead_arn" {
  value = aws_lambda_function.create_lead_lambda.arn
}

output "create_lead_lambda" {
  value = aws_lambda_function.create_lead_lambda
}
output "upload_image_invoke_arn" {
  value = aws_lambda_function.upload_image_lambda.invoke_arn
}

output "upload_image_arn" {
  value = aws_lambda_function.upload_image_lambda.arn
}

output "upload_image_lambda" {
  value = aws_lambda_function.upload_image_lambda
}
