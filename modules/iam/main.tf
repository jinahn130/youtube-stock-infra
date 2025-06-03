data "aws_caller_identity" "current" {}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.env}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# This grants permission to write logs to CLoudWatch for the lambda exec role
# without it lambda cant write logs at all
resource "aws_iam_role_policy_attachment" "basic_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#Now this controls how long the lambda logs are stored.
resource "aws_cloudwatch_log_group" "lambda_log_group_1" {
  name              = "/aws/lambda/${var.env}-youtubeStockResearchReadS3"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "lambda_log_group_2" {
  name              = "/aws/lambda/${var.env}-youtubeStockResearchReadS3SingleVideo"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "lambda_log_group_3" {
  name              = "/aws/lambda/${var.env}-GetPostAllChannel"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "lambda_log_group_4" {
  name              = "/aws/lambda/${var.env}-GetRecentVideosMetadata"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "lambda_log_group_5" {
  name              = "/aws/lambda/${var.env}-GetDigest"
  retention_in_days = 14
}

# Attach Full S3 Access to Lambda
resource "aws_iam_role_policy_attachment" "lambda_full_s3" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach Full DynamoDB Access to Lambda
resource "aws_iam_role_policy_attachment" "lambda_full_dynamo" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Optional: Create IAM user (if still needed)
resource "aws_iam_user" "youtube_stock_user" {
  name = "youtubeStockUser"
}

