# modules/lambda_function/main.tf

#This block is a Terraform data source that queries information about the AWS identity (IAM user, assumed role, etc.) currently executing the Terraform code.
#
data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.env}-${var.name}"
  handler       = "${var.name}.lambda_handler" #lambda function finds the lambda_handler function in {var.name}.py
  runtime       = "python3.9"
  role          = var.role_arn

  # Directly reference your manually built ZIP
  filename = "${path.module}/../../lambda/${var.name}/${var.name}.zip"

  #Use filebase64sha256 to trigger updates when the zip changes
  source_code_hash = filebase64sha256("${path.module}/../../lambda/${var.name}/${var.name}.zip")

  environment {
    variables = var.env_vars
  }
}

/*
Why is api_gateway logic inside the lambda_function module?
- This is there so that each Lambda automatically connects to API Gateway when the Lambda is created.
- Each Lambda module is self-contained.
- You don’t have to manually wire routes/integrations per Lambda elsewhere.
- Simple to scale across multiple Lambdas using for_each

However,
- Your lambda_function module now knows about API Gateway.
- That violates separation of concerns: the module is doing both compute and routing.
- You must pass api_id into every Lambda function.
- Adds complexity to the lambda_function module interface.

-If your app is purely HTTP API-based and you like the simplicity of defining everything together — it’s okay to do this for now.
*/

#Lambda Permission -> Allows API Gateway to invoke the Lambda (permission attached to lambda, not the api gateway)
#(API Gateway itself does not "ask permission" in the way an IAM user or role would.)
#Lambda function must explicitly grant permission to API Gateway to invoke it.
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  # Correctly construct the full ARN for the HTTP API Gateway
  # This allows API Gateway to invoke your Lambda function for any stage (*) and any route (*) under that API ID.
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

#API Gateway Integration ->  Tells API Gateway how to call the Lambda (using Proxy mode when route is triggered)
#This is when API gateway talks to lambda. API Gateway always uses POST internally to call lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route -> Tells API Gateway when to call the Lambda (based on the method + path).
# This is when user talks to API Gateway
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = var.api_id
  route_key = "GET /${var.route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}