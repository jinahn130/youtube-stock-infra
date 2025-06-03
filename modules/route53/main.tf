/*
You must create public hosted zones manually for the first time for DNS from third party.
Namecheap owns the DNS and YOu still have to manually copy 4 created NS to Namecheap
*/

# Creates the hosted zone for the domain passed into the module
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

# ex. Maps your root domain (digestjutsu.com) to your CloudFront distribution using an A record (with alias).
# Q. Does https://digestjutsu.com/GetPostAllChannel go to CloudFront?
# A. yes through this resource
resource "aws_route53_record" "root_domain" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = false
  }
}

# Create A record pointing the dev root domain to s3 bucket website endpoint
# S3 website endpoints do not support A-type alias targets unless you're using CloudFront.
resource "aws_route53_record" "dev_subdomain" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "dev.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.dev_website_endpoint]  # This is fine for CNAME
}