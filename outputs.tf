
#Why we output cloudfront url in the root module although we have the same thing in module/cloudfront?
# Terraform apply does not print module outputs by default. It only prints outputs defined in the root module.
output "cloudfront_url" {
  value = module.cloudfront.cloudfront_domain_name
}