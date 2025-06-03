resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.env}-stock-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://digestjutsu.com"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Custom-Gateway-Secret"]
    expose_headers = ["Content-Type"]
    max_age = 3600
  }
}

# The aws_apigatewayv2_stage resource in API Gateway v2 (HTTP APIs) represents a deployment stage, which is essentially a live environment (like dev, prod, etc.) that clients can send requests to. 
# In API Gateway v2 (HTTP APIs), the stage must be declared explicitly (unlike the old REST APIs which allowed implicit deployment stages).
/*
It binds deployment settings like:
Throttling (rate limits)
Logging
Auto-deployment toggle
It activates your routes and integrations. Without a stage, your API technically exists but is not callable by clients.
*/
/*
Why "$default"?
For HTTP APIs, "$default" is a special stage name that:
Automatically maps all incoming requests (e.g., https://api-id.execute-api.region.amazonaws.com/) without needing a specific path like /dev or /v1.
Simplifies URLs so your routes look like:
https://api-id.execute-api.region.amazonaws.com/myroute
instead of
https://api-id.execute-api.region.amazonaws.com/dev/myroute
So, this block
Enables deployment of your API
Configures throttling and monitoring
Is required for your API to be publicly accessible
Uses $default to simplify URLs and avoid stage prefixes
*/
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  #Rate limiting
  default_route_settings {
    throttling_burst_limit = 100   # Max concurrent requests allowed in a short period
    throttling_rate_limit  = 50    # Average RPS (requests per second)
    detailed_metrics_enabled = false
    logging_level = "ERROR"
    data_trace_enabled = false
  }
}