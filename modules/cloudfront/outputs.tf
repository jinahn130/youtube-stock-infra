# CloudFront distribution domain name (e.g., d123abc.cloudfront.net)
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
  description = "The domain name of the CloudFront distribution"
}

# CloudFront's hosted zone ID (needed for Route53 alias records)
output "cloudfront_zone_id" {
  value = aws_cloudfront_distribution.cdn.hosted_zone_id
  description = "The hosted zone ID to use for Route53 aliasing"
}

# Needed to grant OAC access in S3 bucket policy
output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.cdn.arn
  description = "The ARN of the CloudFront distribution (used in S3 bucket policy for OAC access)"
}