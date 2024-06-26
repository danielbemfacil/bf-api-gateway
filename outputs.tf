output "cognito_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

output "api_gateway_auth_endpoint" {
  value = "${aws_api_gateway_rest_api.api.execution_arn}/auth"
}
