terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

data "archive_file" "build_file" {
  type = "zip"

  source_dir  = "${path.module}/src"
  output_path = "${path.module}/target/build.zip"
}

resource "aws_lambda_function" "sayHello_lambda" {
  function_name = "sayHello"

  filename         = data.archive_file.build_file.output_path
  source_code_hash = filebase64sha256(data.archive_file.build_file.output_path)

  runtime = "nodejs14.x"
  handler = "main.handler"

  role = aws_iam_role.lambda_execution_role.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_executioner_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "sayHello_gateway" {
  name          = "sayHello"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "production_stage" {
  api_id      = aws_apigatewayv2_api.sayHello_gateway.id
  name        = "production"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "sayHello_integration" {
  api_id = aws_apigatewayv2_api.sayHello_gateway.id

  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.sayHello_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "root_route" {
  api_id = aws_apigatewayv2_api.sayHello_gateway.id

  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.sayHello_integration.id}"
}

resource "aws_lambda_permission" "sayHello_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sayHello_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.sayHello_gateway.execution_arn}/*/*"
}
