variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "name" {
  description = "Base name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN that Lambda will use to execute"
  type        = string
}

variable "api_id" {
  description = "API Gateway ID to attach the route to"
  type        = string
}

variable "route_path" {
  description = "The HTTP route path (e.g., /function-name)"
  type        = string
}

variable "env_vars" {
  description = "Environment variables to pass to the Lambda function"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region where the API Gateway is deployed"
  type        = string
}

