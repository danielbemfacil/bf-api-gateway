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

resource "aws_iam_policy" "route53_policy" {
  name        = "Route53Policy"
  description = "Policy to allow Route 53 operations"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZonesByName",
        "route53:GetHostedZone"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/Z01724703N4P77X260KE9"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_ec2_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_logging_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_cognito_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_cognito_policy.arn
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.integration_access_auth_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
  depends_on    = [aws_lambda_function.integration_access_auth_handler]
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_retaguarda" {
  statement_id  = "AllowAPIGatewayInvokeRetaguarda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_transactions_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}


resource "aws_lambda_permission" "allow_api_gateway_to_invoke_retaguarda_accreditation" {
  statement_id  = "AllowAPIGatewayInvokeAccreditation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accreditation_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_cotacao" {
  statement_id  = "AllowAPIGatewayInvokeCotacao"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exchange_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}


resource "aws_lambda_permission" "allow_api_gateway_to_invoke_watchman" {
  statement_id  = "AllowAPIGatewayInvokeWatchman"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.watchman_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
  
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "${var.apiname}-lambda_logging_policy-${var.environment}"
  description = "IAM policy for logging from a lambda"
  policy = jsonencode({
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

resource "aws_iam_policy" "lambda_cognito_policy" {
  name        = "${var.apiname}-lambda_cognito_policy-${var.environment}"
  description = "IAM policy for Cognito actions"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "cognito-idp:AdminSetUserPassword"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${var.cognito_user_pool_id}"
      }
    ]
  })
}
