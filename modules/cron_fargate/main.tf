# -----------------------------------------------------------------------------
# MODULE: modules/cron_fargate/main.tf
# PURPOSE: Trigger ECS Fargate task from an EventBridge (CloudWatch) scheduled rule
# -----------------------------------------------------------------------------

# Define an EventBridge rule to run on a schedule (e.g., cron or rate)
# This replaces the previous schedule that triggered a Lambda function
resource "aws_cloudwatch_event_rule" "cron_schedule" {
  name                = "${var.env}-${var.fargate_name}-cron"
  schedule_expression = var.schedule
  state               = var.enable_cron  # ENABLED or DISABLED to control runtime
}

# CREATE IAM role assumed by EventBridge to trigger ECS runTask
# This role is required because EventBridge must be authorized to start ECS tasks
resource "aws_iam_role" "eventbridge_invoke_role" {
  name = "${var.env}-${var.fargate_name}-eventbridge-role"

  # Trust policy: allow EventBridge to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Policy attached to the EventBridge role allowing it to:
# - Run ECS tasks
# - Pass the task execution role (defined in task definition)
resource "aws_iam_role_policy" "eventbridge_permissions" {
  role = aws_iam_role.eventbridge_invoke_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",             # Launch ECS tasks
          "iam:PassRole"             # Pass task execution role to ECS
        ],
        Resource = "*"               # You can scope this to specific ARNs for tighter security
      }
    ]
  })
}

# This target tells EventBridge to launch an ECS task (on Fargate) whenever the schedule is triggered.
# EventBridge Rule (Triggers a job) -> CloudWatch Event Target (Connects schedule to ECS task) -> ECS runs by fargate
resource "aws_cloudwatch_event_target" "fargate_target" {
  rule      = aws_cloudwatch_event_rule.cron_schedule.name  # Bind to our scheduled rule
  target_id = "ecs-task"                                    # Target ID for identification
  arn       = var.cluster_arn                               # The ECS cluster to run the task in

  # Define what kind of ECS task to launch and how
  ecs_target {
    task_count          = 1                                  # Run one task per schedule
    launch_type         = "FARGATE"                          # Ensure we're using serverless Fargate launch
    task_definition_arn = var.task_definition_arn            # Points to the actual task definition (image, cpu/mem, etc.)

    # Networking setup: subnet(s), security group(s), and public IP if needed
    network_configuration {
      subnets          = var.subnets                         # Subnet(s) for the Fargate task
      assign_public_ip = true                                # Needed if you want outbound internet access (e.g., call APIs)
      security_groups  = var.security_groups                 # Security group(s) that allow outbound HTTP/S
    }

    platform_version = "LATEST"                              # Always use the latest platform for Fargate compatibility
  }

  role_arn = aws_iam_role.eventbridge_invoke_role.arn       # Use the internally created IAM role for EventBridge
}
