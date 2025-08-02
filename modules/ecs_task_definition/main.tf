# -----------------------------------------------------------------------------
# MODULE: modules/ecs_task_definition/main.tf
# PURPOSE: Define ECS Task Definition to run your Python script in Fargate
# -----------------------------------------------------------------------------

# CREATE the IAM role assumed by ECS tasks to pull ECR image and write logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.env}-${var.service_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach basic ECS permissions (pull from ECR, write to CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: allow access to S3/DynamoDB if your script uses them
resource "aws_iam_role_policy" "ecs_extra_permissions" {
  name = "extra-access"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "dynamodb:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Define the ECS task using Fargate
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "${var.env}-${var.service_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"         # 0.5 vCPU — enough for medium performance
  memory                   = "1024"        # 1 GB RAM (free tier level)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn #just using execution role didn't work
  container_definitions = jsonencode([
    {
      name      = "${var.service_name}"
      image     = var.image_uri  # ECR image URI to be injected later
      essential = true
      environment = [
        {
          name  = "OPENAI_API_KEY"
          value = var.openai_api_key
        },
        {
          name  = "YOUTUBE_API_KEY"
          value = var.youtube_api_key
        },
        {
          name  = "DEEPSEEK_API_KEY"
          value = var.deepseek_api_key
        },
        {
          name  = "YOUTUBE_API_KEYS"
          value = jsonencode(var.youtube_api_keys) # <- as JSON string
        },
        {
          name  = "WEBSHARE_USERNAME"
          value = var.webshare_username
        },
        {
          name  = "WEBSHARE_PASSWORD"
          value = var.webshare_password
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${var.service_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Create CloudWatch log group for container output
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 14
}
