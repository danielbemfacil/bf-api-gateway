provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "bemfacil_user_pool"
  
  schema {
    attribute_data_type = "String"
    name                = "ApiKey"
    required            = false
    mutable             = true
  }

  schema {
    attribute_data_type = "String"
    name                = "EstCpfCnpj"
    required            = false
    mutable             = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "bemfacil_client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows = []
  allowed_oauth_scopes = []
  generate_secret = false

  write_attributes = [
    "custom:ApiKey",
    "custom:EstCpfCnpj"
  ]

  read_attributes = [
    "custom:ApiKey",
    "custom:EstCpfCnpj"
  ]
}

# Cognito Domain
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "bemfacil-auth"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# Create a user with custom attributes
resource "aws_cognito_user" "daniel" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = "daniel.nascimento@bemfacil.com.br"
  attributes = {
    "email"             = "daniel.nascimento@bemfacil.com.br"
    "custom:ApiKey"     = "7bf6beb8-8588-4266-a9f0-669b7c31cb4f"
    "custom:EstCpfCnpj" = "09104373430"
  }
  temporary_password = "Guaratuba109@"
  force_alias_creation = false
  message_action = "SUPPRESS" # Do not send invitation message
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "BemFacilAPI"
  description = "API Gateway for BemFacil services"
}

# Resource for /retaguarda
resource "aws_api_gateway_resource" "retaguarda_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "retaguarda"
}

resource "aws_api_gateway_resource" "transacoes_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.retaguarda_resource.id
  path_part   = "transacoes"
}

# Resource for /auth
resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                    = "cognito_authorizer"
  type                    = "COGNITO_USER_POOLS"
  rest_api_id             = aws_api_gateway_rest_api.api.id
  provider_arns           = [aws_cognito_user_pool.user_pool.arn]
  identity_source         = "method.request.header.Authorization"
}

# Method and Integration for /retaguarda/transacoes
resource "aws_api_gateway_method" "retaguarda_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.transacoes_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  depends_on = [
    aws_api_gateway_authorizer.cognito_authorizer
  ]
}

resource "aws_api_gateway_integration" "retaguarda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.transacoes_resource.id
  http_method             = aws_api_gateway_method.retaguarda_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.retaguarda_handler.invoke_arn
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
  uri                     = aws_lambda_function.auth_handler.invoke_arn
}

# Resource for /cotacoes
resource "aws_api_gateway_resource" "cotacoes_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "cotacoes"
}

# Method and Integration for /cotacoes
resource "aws_api_gateway_method" "cotacoes_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.cotacoes_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  depends_on = [
    aws_api_gateway_authorizer.cognito_authorizer
  ]
}

resource "aws_api_gateway_integration" "cotacoes_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.cotacoes_resource.id
  http_method             = aws_api_gateway_method.cotacoes_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:343236792564:function:bf-cotacao-dev-app/invocations"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_method.retaguarda_method,
    aws_api_gateway_integration.retaguarda_integration,
    aws_api_gateway_method.auth_method,
    aws_api_gateway_integration.auth_integration,
    aws_api_gateway_method.cotacoes_method,
    aws_api_gateway_integration.cotacoes_integration,
  ]
}

# IAM Role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

# Attach policy to Lambda role to allow API Gateway to invoke it
resource "aws_lambda_permission" "allow_api_gateway_to_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Provide the source ARN to restrict the permission to this API Gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"

  depends_on = [ aws_lambda_function.auth_handler ]
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_retaguarda" {
  statement_id  = "AllowAPIGatewayInvokeRetaguarda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retaguarda_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Provide the source ARN to restrict the permission to this API Gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Lambda Function for JWT Validation
resource "aws_lambda_function" "jwt_validator" {
  function_name = "jwt_validator"
  runtime       = "python3.10"
  handler       = "jwt_validator.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn

  filename = "lambdas/jwt_validator.zip"
  environment {
    variables = {
      GX_CLIENT_ID = "26e92aef-68b0-4228-9df4-298c9d94847d"
    }
  }
}

# CloudWatch Log Group for Retaguarda Handler
resource "aws_cloudwatch_log_group" "retaguarda_handler_log_group" {
  name              = "/aws/lambda/retaguarda_handler"
  retention_in_days = 14
}

# Lambda Function for Retaguarda Handler
resource "aws_lambda_function" "retaguarda_handler" {
  function_name = "retaguarda_handler"
  runtime       = "python3.10"
  handler       = "retaguarda_handler.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/retaguarda_handler.zip"
  environment {
    variables = {
      GX_CLIENT_ID     = "26e92aef-68b0-4228-9df4-298c9d94847d"
      LOG_GROUP_NAME   = aws_cloudwatch_log_group.retaguarda_handler_log_group.name
    }
  }
}

# CloudWatch Log Group for Auth Handler
resource "aws_cloudwatch_log_group" "auth_handler_log_group" {
  name              = "/aws/lambda/auth_handler"
  retention_in_days = 14
}

# Lambda Function for Auth Handler
resource "aws_lambda_function" "auth_handler" {
  function_name = "auth_handler"
  runtime       = "python3.10"
  handler       = "lambda_auth_function.lambda_handler"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 30

  filename = "lambdas/auth_handler.zip"
  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.user_pool.id
      COGNITO_CLIENT_ID    = aws_cognito_user_pool_client.user_pool_client.id
      LOG_GROUP_NAME       = aws_cloudwatch_log_group.auth_handler_log_group.name
    }
  }
}

# Policy to allow Lambda to write logs to CloudWatch
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging_policy"
  description = "IAM policy for logging from a lambda"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Policy to allow Lambda to perform AdminSetUserPassword
resource "aws_iam_policy" "lambda_cognito_policy" {
  name        = "lambda_cognito_policy"
  description = "IAM policy for Cognito actions"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "cognito-idp:AdminSetUserPassword"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${aws_cognito_user_pool.user_pool.id}"
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


