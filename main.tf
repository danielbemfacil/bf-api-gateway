provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.apiname}-${var.environment}" 
  description = var.apidescription
}

# Resource for /customer
resource "aws_api_gateway_resource" "customer_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "customer"
}

resource "aws_api_gateway_resource" "card_transactions_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.customer_resource.id
  path_part   = "card-transactions"
}

# Resource for /auth
resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "bf_integration_access_authorizer" {
  name            = "bf-integration-access-authorizer-${var.environment}"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  provider_arns   = [var.userpoolarn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_model" "card_transaction_request_model" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name        = "CardTransactionRequestModel"
  content_type = "application/json"
  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "CardTransactionRequestModel",
  "type": "object",
  "properties": {
    "DataInicio": {
      "type": "string"
    },
    "DataFinal": {
      "type": "string"
    },
    "NSU": {
      "type": "string"
    }
  },
  "required": ["DataInicio", "DataFinal"]
}
EOF
}


# Method and Integration for /retaguarda/transacoes
resource "aws_api_gateway_method" "card_transaction_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.card_transactions_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.bf_integration_access_authorizer.id
  api_key_required = true

  request_parameters = {
    "method.request.header.x-api-key" = true
  }

  request_models = {
    "application/json" = "CardTransactionRequestModel"
  }


  depends_on = [
    aws_api_gateway_authorizer.bf_integration_access_authorizer
  ]
}

resource "aws_api_gateway_integration" "card_transaction_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.card_transactions_resource.id
  http_method             = aws_api_gateway_method.card_transaction_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_transactions_handler.invoke_arn

  request_parameters = {
    "integration.request.header.x-api-key" = "method.request.header.x-api-key"
  }

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
  "DataInicio": "$inputRoot.DataInicio",
  "DataFinal": "$inputRoot.DataFinal",
  "NSU": "$inputRoot.NSU"
}
EOF
  }

}




# Resource for /cotacoes
resource "aws_api_gateway_resource" "exchange_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "exchange"
}

# Resource for /getCotacoes
resource "aws_api_gateway_resource" "get_exchange_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.exchange_resource.id
  path_part   = "list"
}

# Method and Integration for /list
resource "aws_api_gateway_method" "get_exchange_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.get_exchange_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.bf_integration_access_authorizer.id

  depends_on = [
    aws_api_gateway_authorizer.bf_integration_access_authorizer
  ]
}

resource "aws_api_gateway_integration" "get_exchange_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.get_exchange_resource.id
  http_method             = aws_api_gateway_method.get_exchange_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.exchange_handler.invoke_arn
}

# Method and Integration for /auth
resource "aws_api_gateway_method" "auth_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.auth_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.auth_resource.id
  http_method             = aws_api_gateway_method.auth_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.integration_access_auth_handler.invoke_arn
}



# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_method.card_transaction_method,
    aws_api_gateway_integration.card_transaction_integration,
    aws_api_gateway_method.auth_method,
    aws_api_gateway_integration.auth_integration,
    aws_api_gateway_method.get_exchange_method,
    aws_api_gateway_integration.get_exchange_integration,
  ]
}
# IAM Role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.apiname}-iam_for_lambda-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "${var.apiname}-lambda_ec2_policy-${var.environment}"
  description = "Policy for Lambda to manage network interfaces"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_ec2_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# Attach policy to Lambda role to allow API Gateway to invoke it
resource "aws_lambda_permission" "allow_api_gateway_to_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.integration_access_auth_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Provide the source ARN to restrict the permission to this API Gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"

  depends_on = [aws_lambda_function.integration_access_auth_handler]
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_retaguarda" {
  statement_id  = "AllowAPIGatewayInvokeRetaguarda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_transactions_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Provide the source ARN to restrict the permission to this API Gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Permissão para API Gateway invocar a função Lambda bf-cotacao-dev-app
resource "aws_lambda_permission" "allow_api_gateway_to_invoke_cotacao" {
  statement_id  = "AllowAPIGatewayInvokeCotacao"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchange_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Forneça o ARN da fonte para restringir a permissão a este API Gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# CloudWatch Log Group for Retaguarda Handler
resource "aws_cloudwatch_log_group" "card_transactions_handler_log_group" {
  name              = "/aws/lambda/card_transactions_handler-${var.environment}"
  retention_in_days = 14
}

# Lambda Function for Retaguarda Handler
resource "aws_lambda_function" "card_transactions_handler" {
  function_name = "card_transactions_handler-${var.environment}"
  runtime       = "python3.10"
  handler       = "card_transactions_handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/card_transactions_handler.zip"
  vpc_config {
    security_group_ids = var.sg_ids
    subnet_ids         = var.subnets_ids
  }
  environment {
    variables = {
      GX_CLIENT_ID   = var.gx_client_id
      LOG_GROUP_NAME = aws_cloudwatch_log_group.card_transactions_handler_log_group.name
    }
  }
}


# CloudWatch Log Group for Cotacoes Handler
resource "aws_cloudwatch_log_group" "exchange_handler_log_group" {
  name              = "/aws/lambda/exchange_handler-${var.environment}"
  retention_in_days = 14
}

# Lambda Function for Retaguarda Handler
resource "aws_lambda_function" "exchange_handler" {
  function_name = "exchange_handler-${var.environment}"
  runtime       = "python3.10"
  handler       = "exchange_handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/exchange_handler.zip"
  vpc_config {
    security_group_ids = var.sg_ids
    subnet_ids         = var.subnets_ids
  }
  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.exchange_handler_log_group.name
    }
  }
}

# CloudWatch Log Group for Auth Handler
resource "aws_cloudwatch_log_group" "integration_access_auth_handler_log_group" {
  name              = "/aws/lambda/integration_access_auth_handler-${var.environment}"
  retention_in_days = 14
}

# Lambda Function for Auth Handler
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

# Policy to allow Lambda to write logs to CloudWatch
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "${var.apiname}-lambda_logging_policy-${var.environment}"
  description = "IAM policy for logging from a lambda"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Policy to allow Lambda to perform AdminSetUserPassword
resource "aws_iam_policy" "lambda_cognito_policy" {
  name        = "${var.apiname}-lambda_cognito_policy-${var.environment}"
  description = "IAM policy for Cognito actions"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "cognito-idp:AdminSetUserPassword"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${var.cognito_user_pool_id}"
      }
    ]
  })
}

# Attach the logging policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_lambda_logging_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}


# Attach the cognito policy to the Lambda role
resource "aws_iam_role_policy_attachment" "attach_lambda_cognito_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_cognito_policy.arn
}


