resource "aws_lambda_function" "ap-lambda-fn" {
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  function_name = "ap-lambda-function-6nov"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"

  code_signing_config_arn        = aws_lambda_code_signing_config.ap-lambda
  reserved_concurrent_executions = 50
  dead_letter_config {
    target_arn = "test"
  }
  tracing_config {
    mode = "Active"
  }

  filename         = "${path.module}/../python/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../python/lambda_function.zip")
}

resource "aws_lambda_code_signing_config" "ap-lambda" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile_version.example.arn]
  }
}