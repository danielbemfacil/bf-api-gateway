resource "aws_cloudwatch_log_group" "card_transactions_handler_log_group" {
  name              = "/aws/lambda/card_transactions_handler-${var.environment}"
  retention_in_days = 14
}

resource "aws_lambda_function" "card_transactions_handler" {
  function_name = "card_transactions_handler-${var.environment}"
  runtime       = "python3.10"
  handler       = "card_transactions_handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/card_transactions_handler.zip"
  
  environment {
    variables = {
      GX_CLIENT_ID   = var.gx_client_id
      LOG_GROUP_NAME = aws_cloudwatch_log_group.card_transactions_handler_log_group.name
    }
  }
}

resource "aws_cloudwatch_log_group" "exchange_handler_log_group" {
  name              = "/aws/lambda/exchange_handler-${var.environment}"
  retention_in_days = 14
}

resource "aws_lambda_function" "exchange_handler" {
  function_name = "exchange_handler-${var.environment}"
  runtime       = "python3.10"
  handler       = "exchange_handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/exchange_handler.zip"
  
  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.exchange_handler_log_group.name
    }
  }
}

resource "aws_cloudwatch_log_group" "integration_access_auth_handler_log_group" {
  name              = "/aws/lambda/integration_access_auth_handler-${var.environment}"
  retention_in_days = 14
}

resource "aws_lambda_function" "integration_access_auth_handler" {
  function_name = "integration_access_auth_handler-${var.environment}"
  runtime       = "python3.10"
  handler       = "lambda_auth_function.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/integration_access_auth_handler.zip"
  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      LOG_GROUP_NAME       = aws_cloudwatch_log_group.integration_access_auth_handler_log_group.name
    }
  }
}
