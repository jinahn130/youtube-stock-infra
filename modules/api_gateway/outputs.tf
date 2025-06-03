output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "api_domain_name" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}