# Task definition ARN to be passed to the Fargate cron trigger module
output "task_definition_arn" {
  description = "ARN of the ECS task definition to be run"
  value       = aws_ecs_task_definition.fargate_task.arn
}

# IAM role used by ECS to run the task (grants permissions to use ECR, logs, etc.)
output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

# Log group for container stdout/stderr
output "log_group_name" {
  description = "CloudWatch log group for ECS task output"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}
