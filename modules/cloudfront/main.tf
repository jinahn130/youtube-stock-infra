# modules/cloudfront/main.tf
/*
Receive certificate_arn as an input (from your acm module)
Maintain output values for cloudfront_domain_name and s3_bucket_name
Dynamically generate ordered cache behaviors for your 5 API endpoints with custom TTL
*/

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Create Origin Access Control for S3 bucket
# When you create OAC, you associate this OAC with the distribution, then secure s3 origin, so only this distribution can access the object.
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Individual cache policies for each API endpoint with specific TTLs
resource "aws_cloudfront_cache_policy" "post_all_channel" {
  name = "PostAllChannel-Cache-5min"
  default_ttl = 300
  max_ttl     = 600
  min_ttl     = 60
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Origin"]
      }
    }
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

resource "aws_cloudfront_cache_policy" "recent_metadata" {
  name = "RecentMetadata-Cache-5min"
  default_ttl = 300
  max_ttl     = 600
  min_ttl     = 60
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Origin"]
      }
    }
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

resource "aws_cloudfront_cache_policy" "read_single_video" {
  name = "ReadSingleVideo-Cache-1d"
  default_ttl = 86400
  max_ttl     = 86400
  min_ttl     = 300
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Origin"]
      }
    }
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

resource "aws_cloudfront_cache_policy" "read_channel" {
  name = "ReadChannel-Cache-60min"
  default_ttl = 3600
  max_ttl     = 21600
  min_ttl     = 60
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Origin"]
      }
    }
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

resource "aws_cloudfront_cache_policy" "digest" {
  name = "Digest-Cache-6h"
  default_ttl = 21600
  max_ttl     = 86400
  min_ttl     = 60
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = ["Origin"]
      }
    }
    cookies_config { cookie_behavior = "none" }
    query_strings_config { query_string_behavior = "all" }
  }
}

#added for the ads
resource "aws_cloudfront_cache_policy" "no_cache_html" {
  name = "NoCache-SPA-IndexHTML"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}


/* ---- declare cloudfront distribution ----
  - Tip 1:Routes requests from https://digestjutsu.com -> origin like S3 bucket for static React app, API Gateway for data calls
  - Tip 2:Cloudfront distribution will cache the API calls based on path.
  - Tip 3:bucket_regional_domain_name is used over bucketname
  
  - why bucket_regional_domain name?
    CloudFront requires a DNS-resolvable and region-specific origin when using the S3 REST API endpoint,
    not just the static website endpoint and not just the bucket name.
  
  - Why need cloudfront for https?
    web S3 bucket does not support Origin Access Control (OAC) or Origin Access Identity (OAI).
    You cannot block the public access and try to access it publicly.
    If S3 is public, anyone with the website url can bypass CloudFront and access your bucket directly.
  -------------------------------------------*/
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]

  # ---- S3 Origin (for static website) ----
  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # ---- API Gateway Origin (for APIs) ----
  origin {
    domain_name = var.api_gateway_domain_name
    origin_id   = "APIGatewayOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    #Custom Secret. Cloudfront attaches this custom header on its request to API gateway
    custom_header {
      name  = "X-Custom-Gateway-Secret"
      value = var.api_gateway_secret_header_value
    }
  }



  #digestjutsu.com/<whatever page that does not exist hits this cache>
  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD", "OPTIONS"] #Preflight OPTIONS method allowed, but not cached
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    #cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cache_policy_id = aws_cloudfront_cache_policy.no_cache_html.id
  }

  #allows digestjutsu.com/GetPostAllChannel path to hit this cache
  #target_origin_id routes this to origin with origin_id APIGatewayOrigin
  ordered_cache_behavior {
    path_pattern           = "/GetPostAllChannel"
    target_origin_id       = "APIGatewayOrigin"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.post_all_channel.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/GetRecentVideosMetadata"
    target_origin_id       = "APIGatewayOrigin"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.recent_metadata.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/youtubeStockResearchReadS3SingleVideo"
    target_origin_id       = "APIGatewayOrigin"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.read_single_video.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/youtubeStockResearchReadS3"
    target_origin_id       = "APIGatewayOrigin"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.read_channel.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/GetDigest"
    target_origin_id       = "APIGatewayOrigin"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.digest.id
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

#--------------------------------------------------------------------------------------------------------
#|Create CloudWatch Alaram on CloudFront Request Metric to prevent malicious users (to save cost on WAF)|
#
resource "aws_cloudwatch_metric_alarm" "high_rps_cloudfront" {
  alarm_name          = "HighRPS-CloudFront"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60 # evaluate every 60 seconds
  threshold           = 20000 # 60,000 requests/min = 1000 RPS
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  metric_name = "Requests"
  namespace   = "AWS/CloudFront"
  dimensions = {
    DistributionId = aws_cloudfront_distribution.cdn.id
    Region         = "Global"
  }

  alarm_description = "Triggers if CloudFront exceeds 1000 requests per second"
  alarm_actions     = [aws_sns_topic.alerts.arn] # Your notification mechanism
}

resource "aws_sns_topic" "alerts" {
  name = "cloudfront-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "jinahn130@gmail.com" # Change this
}
#----------------------------------------------------------------------------------------------