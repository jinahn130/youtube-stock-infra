
variable "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (used as CloudFront origin)"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "API Gateway domain name to be used as CloudFront origin"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the CloudFront distribution (e.g., digestjutsu.com)"
  type        = string
}

# Add a Terraform variable to store your shared secret header value
variable "api_gateway_secret_header_value" {
  type        = string
  description = "Shared secret header value to restrict CloudFront -> API Gateway access"
  default     = "sec-value-206"
}