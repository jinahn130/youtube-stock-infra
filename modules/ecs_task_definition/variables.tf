# Environment identifier (e.g., dev, prod)
variable "env" {
  description = "Environment name used for tagging and naming"
  type        = string
}

# Name of the ECS service/app (used for naming log groups, roles, etc.)
variable "service_name" {
  description = "Logical name for this ECS service (used in resource names)"
  type        = string
}

# ECR image URI to use in the container definition
# Format: <account_id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>
variable "image_uri" {
  description = "Full URI of the Docker image to run"
  type        = string
}

# AWS region (used for log group configuration)
variable "region" {
  description = "AWS region to deploy ECS task and CloudWatch logs"
  type        = string
}

variable "openai_api_key" {}
variable "youtube_api_key" {}
variable "deepseek_api_key" {}

variable "youtube_api_keys" {
  type        = list(string)
  description = "Optional list of YouTube API keys"
  default     = []
}

variable "webshare_username" {
  type        = string
  description = "Optional Webshare proxy username"
  default     = ""
}

variable "webshare_password" {
  type        = string
  description = "Optional Webshare proxy password"
  default     = ""
}