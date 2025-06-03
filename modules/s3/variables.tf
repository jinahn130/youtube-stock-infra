variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "Optional ARN of CloudFront distribution for OAC access"
  type        = string
  default     = null
}