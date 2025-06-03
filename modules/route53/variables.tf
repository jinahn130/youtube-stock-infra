variable "domain_name" {
  description = "The root domain (e.g., digestjutsu.com)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  type        = string
}

variable "cloudfront_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution"
  type        = string
}

variable "dev_website_endpoint" {
  description = "S3 website endpoint for dev digestjutsu"
  type        = string
}