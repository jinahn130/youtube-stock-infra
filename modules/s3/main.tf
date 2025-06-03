resource "aws_s3_bucket" "frontend" {
  bucket        = var.bucket_name
  force_destroy = true
}

#CloudFront SPA Fallback
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Block all public access (required when using CloudFront OAC)
# Good to know: Might not need this resource if no dev.digestjutsu.com since by default Block Public Access is enabled
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.frontend.id

  #block all public access for prod cloudfront + s3 use. But do not block for dev endpoint.
  block_public_acls       = var.environment != "dev"
  block_public_policy     = var.environment != "dev"
  ignore_public_acls      = var.environment != "dev"
  restrict_public_buckets = var.environment != "dev"
}


#IMPORTANT:
#Cloundfront -> S3 uses OAC (OAI is old)
# You still need S3 bucket policy to explicitly allow CloudFront to access S3
# By Only allowing access by the CloudFront distribution ARN. 
# Note that CloudFront signs requests with its service principal (cloudfront.amazonaws.com)
# S3 bucket authorize only that principal for your specific CloudFront distribution
resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
  
  # Using Statement is better over count because value like cloudfront_distribution_arn is not known until apply time
  # Tried using terraform apply -target module.cloudfront but no success.
  # Instead, commenting out this bucket policy until cloundfront has been created, then executing this.
  count = var.cloudfront_distribution_arn != null && length(var.cloudfront_distribution_arn) > 0 ? 1 : 0

  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowCloudFrontServiceRead",
        Effect: "Allow",
        Principal: {
          Service: "cloudfront.amazonaws.com"
        },
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.frontend.arn}/*",
        Condition: {
          StringEquals: {
            "AWS:SourceArn": var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "allow_public_read_dev" {
  count = var.environment == "dev" ? 1 : 0

  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowPublicRead",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}