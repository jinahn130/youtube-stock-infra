/*
This module
Issues an ACM certificate for your domain (e.g., digestjutsu.com).
Validates the certificate via DNS using Route 53.
Makes this certificate usable by CloudFront, which requires the cert to be in us-east-1 
(which you correctly set via provider "aws" { alias = "us_east_1" }).
*/


# Use AWS provider in us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Load the Route53 hosted zone for the domain
# a data source in Terraform that tells Terraform to look up an existing Route 53 hosted zone for the domain you specify (e.g., digestjutsu.com), rather than trying to create a new one.
# data blocks mean reference existing resource
data "aws_route53_zone" "primary" {
  name         = var.domain_name

  #private zone = false for domains accessible on public internet.
  #private zone is yes for private internal DNS zone used within a VPC.
  private_zone = false
}

# Request a public SSL certificate for your domain
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


# Create a Route 53 DNS record to validate the ACM certificate
/* 
example. ACM Validation DNS Record

The aws_route53_record used for ACM validation is not a permanent DNS record — it's a short-lived TXT or CNAME record for validating ownership during cert creation.
It is only relevant to the ACM module, and must be created at the same time as aws_acm_certificate.
If you move the record into modules/route53/, you'd end up:
    Spliting logic that’s tightly coupled (ACM + validation record)
    Adding unnecessary complexity wiring certificate.domain_validation_options across modules
    Risking breaking the cert validation process if timing or dependencies aren't handled carefully
Purpose: Proves you own the domain to issue the SSL cert
Lifecycle: Temporary (used once, updated if cert changes)
*/
locals {
  validation_option = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0)
}

resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = local.validation_option.resource_record_name
  type    = local.validation_option.resource_record_type
  records = [local.validation_option.resource_record_value]
  ttl     = 60
}

# Finalize the certificate validation using the DNS record above
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
