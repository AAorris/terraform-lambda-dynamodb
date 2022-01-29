variable "aws_region" {
  # Change this to your preferred region
  default = "us-west-2"
}

provider "aws" {
  region = var.aws_region
}

# zip lambda_function.zip index.js
# Later, it may be better to use source_dir than source_file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.js"
  output_path = "lambda_function.zip"
}

# Use the exported handler to create a lambda function
resource "aws_lambda_function" "main" {
  filename         = "lambda_function.zip"
  function_name    = "main"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs14.x"
}

# IAM role for lambda
resource "aws_iam_role" "lambda" {
  name = "lambda"

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

resource "aws_api_gateway_rest_api" "ingress" {
  name        = "LambdaGateway"
  description = "Gateway -> Lambda -> DynamoDB ingress"
}

# Gateway "resource"
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.ingress.id
  parent_id   = aws_api_gateway_rest_api.ingress.root_resource_id
  path_part   = "test" # /test
}

# Gateway "method"
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.ingress.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Gateway "integration" (method -> lambda)
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.ingress.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

# Gateway "deployment"
resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.ingress.id
  stage_name  = "test"
}

resource "aws_lambda_permission" "gateway_may_call_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.ingress.execution_arn}/*/*"
}

# DynamoDB table
resource "aws_dynamodb_table" "sandbox" {
  name         = "sandbox"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "key"
    type = "S"
  }
  tags = {
    environment = "test"
  }
}

resource "aws_iam_role_policy" "lambda_may_use_database" {
  name   = "dynamodb_lambda_policy"
  role   = aws_iam_role.lambda.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": "${aws_dynamodb_table.sandbox.arn}"
    }
  ]
}
EOF
}
