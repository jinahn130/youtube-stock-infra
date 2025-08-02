variable "aws_region" {
  default = "us-east-2"
}

variable "env" {}
variable "youtube_api_key" {}
variable "openai_api_key" {}

variable "domain_name" {}

variable "youtubeStockResearch_image_uri" {
  description = "ECR image URI for youtubeStockResearch container"
  type        = string
}

variable "createDigest_image_uri" {
  description = "ECR image URI for CreateDigest container"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS networking"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the Fargate task"
  type        = list(string)
}

variable "webshare_username" {
  description = "Webshare proxy username"
  type        = string
}

variable "webshare_password" {
  description = "Webshare proxy password"
  type        = string
}

variable "youtube_api_keys" {
  description = "List of YouTube API keys for quota rotation"
  type        = list(string)
}