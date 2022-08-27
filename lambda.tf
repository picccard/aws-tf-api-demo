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

  source_dir  = "${path.module}/hello"
  output_path = "${path.module}/hello.zip"
}

resource "aws_lambda_function" "hello" {
  function_name = "hello"

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  filename = data.archive_file.hello.output_path
  source_code_hash = data.archive_file.hello.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}