resource "aws_lambda_function" "ap-lambda-fn" {
  function_name    = "ap-lambda-function-6nov"
  runtime          = "python3.10"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../python/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../python/lambda_function.zip")
}