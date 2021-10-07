
output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.sayHello_lambda.function_name
}

output "function_arn" {
  description = "ARN for the function."

  value = aws_lambda_function.sayHello_lambda.arn
}


output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.production_stage.invoke_url
}
