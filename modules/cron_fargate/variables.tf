# Environment name (e.g., dev, prod)
variable "env" {
  description = "The environment name (used in naming resources)"
  type        = string
}

# Name of the Fargate job (used in naming EventBridge resources)
variable "fargate_name" {
  description = "Logical name for the ECS Fargate job"
  type        = string
}

# Cron or rate expression for scheduling
# Example: cron(0 11 * * ? *) — every day at 11:00 UTC
variable "schedule" {
  description = "EventBridge schedule expression (cron or rate)"
  type        = string
}

# State of the EventBridge rule: ENABLED or DISABLED
variable "enable_cron" {
  description = "Whether the cron rule is enabled or disabled"
  type        = string
  default     = "DISABLED"
}

# ARN of the ECS task definition to run (includes container definition)
variable "task_definition_arn" {
  description = "ARN of the ECS task definition to launch"
  type        = string
}

# ARN of the ECS cluster where task will be run
variable "cluster_arn" {
  description = "ARN of the ECS cluster to run the Fargate task"
  type        = string
}

# List of subnet IDs for the Fargate task (must be in same VPC)
variable "subnets" {
  description = "List of subnet IDs for ECS networking"
  type        = list(string)
}

# List of security group IDs assigned to the Fargate task
variable "security_groups" {
  description = "List of security groups for the Fargate task"
  type        = list(string)
}