# ------------------------------------------------------------------
# outputs.tf for modules/cron_fargate
# Purpose: Expose useful information for debugging or downstream use
# ------------------------------------------------------------------

# Name of the EventBridge rule (for visibility/debugging)
output "event_rule_name" {
  description = "The name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.cron_schedule.name
}

# ARN of the EventBridge rule
output "event_rule_arn" {
  description = "ARN of the EventBridge rule (can be used in CloudWatch or logs)"
  value       = aws_cloudwatch_event_rule.cron_schedule.arn
}

# Target ID of the Fargate task
output "event_target_id" {
  description = "Target ID used in EventBridge rule"
  value       = aws_cloudwatch_event_target.fargate_target.target_id
}
