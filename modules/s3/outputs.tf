output "bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

#legacy global website endpoint for S3. Used for Route53 -> s3
output "bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

#digestjutsu-frontend-prod.s3.us-east-2.amazonaws.com
output "bucket_regional_domain_name" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}