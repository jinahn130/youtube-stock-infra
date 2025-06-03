provider "aws" {
  region = var.aws_region
}

locals {
  functions = [
    "youtubeStockResearch",
    "youtubeStockResearchReadS3",
    "youtubeStockResearchReadS3SingleVideo",
    "GetPostAllChannel",
    "GetRecentVideosMetadata",
    "CreateDigest",
    "GetDigest"
  ]
}

module "api" {
  source = "./modules/api_gateway"
  env    = var.env
}

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
}

module "cloudfront" {
  source                  = "./modules/cloudfront"
  domain_name             = var.domain_name
  certificate_arn         = module.acm.certificate_arn
  api_gateway_domain_name = replace(module.api.api_domain_name, "https://", "")
  bucket_regional_domain_name   = module.s3.bucket_regional_domain_name
}

module "iam" {
  source = "./modules/iam"
  env    = var.env
}


module "lambda_functions" {
  for_each = toset(local.functions)
  source   = "./modules/lambda_function"
  name     = each.value
  env      = var.env
  role_arn = module.iam.lambda_role_arn
  api_id   = module.api.api_id
  route_path = each.value
  env_vars   = {
    YOUTUBE_API_KEY  = var.youtube_api_key
    OPENAI_API_KEY   = var.openai_api_key
    DEEPSEEK_API_KEY = var.deepseek_api_key
  }
 aws_region = var.aws_region
}

module "route53" {
  source                      = "./modules/route53"
  domain_name                 = var.domain_name
  cloudfront_domain_name      = module.cloudfront.cloudfront_domain_name
  cloudfront_zone_id          = module.cloudfront.cloudfront_zone_id
  dev_website_endpoint        = module.s3_dev.bucket_website_endpoint
}

module "s3" {
  source      = "./modules/s3"
  environment = "prod"
  bucket_name = "digestjutsu-frontend-prod"
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
}

module "s3_dev" {
  source      = "./modules/s3"
  environment = "dev"
  bucket_name = "dev.digestjutsu.com" #bucket name must be dev.digestjutsu.com for route53 -> s3
}

#Create ECS cluster for ECS/fargate
resource "aws_ecs_cluster" "main" {
  name = "${var.env}-main-cluster"
}

# -------------------------
# Task: youtubeStockResearch
# -------------------------
module "youtubeStockResearch_task" {
  source       = "./modules/ecs_task_definition"
  env          = var.env
  service_name = "youtube-stock-ingestion"
  image_uri    = var.youtubeStockResearch_image_uri
  region       = var.aws_region

  # Pass secrets into ECS container
  openai_api_key     = var.openai_api_key
  youtube_api_key    = var.youtube_api_key
  deepseek_api_key   = var.deepseek_api_key
}

module "youtubeStockResearch_cron" {
  source                = "./modules/cron_fargate"
  env                   = var.env
  fargate_name          = "youtube-stock-ingestion"
  schedule              = "cron(0 11 * * ? *)"  # Daily at 11:00 UTC
  enable_cron           = "ENABLED"
  task_definition_arn   = module.youtubeStockResearch_task.task_definition_arn
  cluster_arn           = aws_ecs_cluster.main.arn
  subnets               = var.subnet_ids
  security_groups       = var.security_group_ids
}

# -------------------------
# Task: CreateDigest
# -------------------------
module "CreateDigest_task" {
  source       = "./modules/ecs_task_definition"
  env          = var.env
  service_name = "digest-generator"
  image_uri    = var.createDigest_image_uri
  region       = var.aws_region

  # Pass secrets into ECS container
  openai_api_key     = var.openai_api_key
  youtube_api_key    = var.youtube_api_key
  deepseek_api_key   = var.deepseek_api_key
}

module "CreateDigest_cron" {
  source                = "./modules/cron_fargate"
  env                   = var.env
  fargate_name          = "digest-generator"
  schedule              = "cron(30 12 ? * MON-FRI *)"  # Weekdays at 12:30 UTC
  enable_cron           = "ENABLED"
  task_definition_arn   = module.CreateDigest_task.task_definition_arn
  cluster_arn           = aws_ecs_cluster.main.arn
  subnets               = var.subnet_ids
  security_groups       = var.security_group_ids
}

/*CRON -> Lambda job not used anymore
# Add cron job for one lambda only
module "youtubeStockResearch_cron" {
  source      = "./modules/cron"
  env         = var.env
  lambda_arn  = module.lambda_functions["youtubeStockResearch"].lambda_arn
  lambda_name = module.lambda_functions["youtubeStockResearch"].lambda_name
  schedule    = "cron(0 11 * * ? *)"  # Every day at 11:00 UTC (7am EST/8am EDT)
  enable_cron = "ENABLED"  # Set to true later when you want it active

  eventbridge_input_json = jsonencode({
    body = jsonencode({
      fetchByTopVideos     = true,
      fetchBynumberOfDays  = -1
    })
  })
}

# Add cron job for one lambda only
module "CreateDigest_cron" {
  source      = "./modules/cron"
  env         = var.env
  lambda_arn  = module.lambda_functions["CreateDigest"].lambda_arn
  lambda_name = module.lambda_functions["CreateDigest"].lambda_name
  schedule    = "cron(30 12 ? * MON-FRI *)"  # Weekdays at 12:30 UTC (8:30am EST/9:30am EDT)
  enable_cron = "ENABLED"  # Set to ENABLED later when you want it active

  eventbridge_input_json = "{}"
}
*/

# Optional: outputs for inspection/debugging
output "youtubeStockResearch_task_def" {
  value = module.youtubeStockResearch_task.task_definition_arn
}

output "CreateDigest_task_def" {
  value = module.CreateDigest_task.task_definition_arn
}

output "debug_bucket_domain_name" {
  value = module.s3.bucket_regional_domain_name
}

output "debug_api_domain_name" {
  value = module.api.api_domain_name
}