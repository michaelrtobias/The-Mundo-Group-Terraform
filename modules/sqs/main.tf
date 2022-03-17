resource "aws_sqs_queue" "send_email" {
  name = "send_email"
  # message_retention_seconds = 60
  visibility_timeout_seconds = 240
}

resource "aws_sqs_queue_policy" "send_email" {
  queue_url = aws_sqs_queue.send_email.url

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.send_email.arn}"
    },
    {
      "Sid": "Allowsqsinvokesendemail",
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "${var.send_email_lambda.arn}"
    }
  ]
}
POLICY
}

resource "aws_lambda_event_source_mapping" "send_email" {
  event_source_arn = aws_sqs_queue.send_email.arn
  function_name    = var.send_email_lambda.arn
}
