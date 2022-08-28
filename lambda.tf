resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "hello" {
  type = "zip"

  source_dir  = "./src/hello"
  output_path = "./builds/hello.zip"
}

data "archive_file" "event" {
  type = "zip"

  source_dir  = "./src/event"
  output_path = "./builds/event.zip"
}

resource "aws_lambda_function" "hello" {
  function_name = "hello"

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  filename = data.archive_file.hello.output_path
  source_code_hash = data.archive_file.hello.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function" "event" {
  function_name = "event"

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  filename = data.archive_file.event.output_path
  source_code_hash = data.archive_file.event.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "hello" {
  name = "/aws/lambda/${aws_lambda_function.hello.function_name}"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "event" {
  name = "/aws/lambda/${aws_lambda_function.event.function_name}"

  retention_in_days = 30
}