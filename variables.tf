variable "aws_region" {
  default = "us-east-2"
}

variable "env" {}
variable "youtube_api_key" {}
variable "openai_api_key" {}
variable "deepseek_api_key" {}
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