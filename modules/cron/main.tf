/*
#Defines the schedule
resource "aws_cloudwatch_event_rule" "cron_schedule" {
  name                = "${var.env}-${var.lambda_name}-cron"
  schedule_expression = var.schedule
  state               = var.enable_cron  # Controls whether rule is active or disabled. Meanwhile if this was  count = var.enable_cron ? 1 : 0, then resource would be deleted. Also, aws_cloudwatch_event_rule.cron_schedule would become an array.
}

/*
This just links the rule (the schedule) to the Lambda function.
It doesn’t trigger anything on its own.
If the rule is disabled, this target is ignored by AWS — no events are sent to it.
*/
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cron_schedule.name
  target_id = "lambda"
  arn       = var.lambda_arn

  input = var.eventbridge_input_json
}


/*
This grants CloudWatch Events permission to invoke your Lambda.
It must exist so AWS can attempt to trigger the Lambda — but if the rule is disabled, no trigger occurs.
It's just a permission gate; it doesn't schedule or invoke anything on its own.
*/
resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_schedule.arn
}
*/