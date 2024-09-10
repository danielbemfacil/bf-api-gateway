resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.apiname}-${var.environment}"
  description = var.apidescription
}

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

resource "aws_api_gateway_resource" "accreditation_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.customer_resource.id
  path_part   = "new"
}

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_authorizer" "bf_integration_access_authorizer" {
  name            = "bf-integration-access-authorizer-${var.environment}"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  provider_arns   = [var.userpoolarn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_model" "card_transaction_request_model" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "CardTransactionRequestModel"
  content_type = "application/json"
  schema       = <<EOF
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

resource "aws_api_gateway_model" "card_transaction_response_success_model" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "CardTransactionResponseSuccessModel"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "CardTransactionResponseSuccessModel",
  "type": "object",
  "properties": {
    "Transacoes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "EstNomFan": { "type": "string" },
          "VanTrnCodDsc": { "type": "string" },
          "VanTrnDta": { "type": "string" },
          "VanTrnHraFor": { "type": "string" },
          "VanTrnNsu": { "type": "string" },
          "VanTrnNsuOri": { "type": "string" },
          "VanTrnNumAtz": { "type": "string" },
          "VanTrnPosNumSer": { "type": "string" },
          "VanTrnQtdPar": { "type": "integer" },
          "VanTrnSeq": { "type": "string" },
          "VanTrnStsDsc": { "type": "string" },
          "VanTrnTipPrdDsc": { "type": "string" },
          "VanTrnVlr": { "type": "string" }
        }
      }
    },
    "ret_cod": { "type": "integer" },
    "ret_dsc": { "type": "string" }
  },
  "required": ["Transacoes", "ret_cod", "ret_dsc"]
}
EOF
}

resource "aws_api_gateway_model" "card_transaction_response_failure_model" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "CardTransactionResponseFailureModel"
  content_type = "application/json"
  schema       = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "CardTransactionResponseFailureModel",
  "type": "object",
  "properties": {
    "ret_cod": { "type": "integer" },
    "ret_dsc": { "type": "string" }
  },
  "required": ["ret_cod", "ret_dsc"]
}
EOF
}


resource "aws_api_gateway_method" "accreditation_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.accreditation_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.bf_integration_access_authorizer.id
  depends_on = [
    aws_api_gateway_authorizer.bf_integration_access_authorizer
  ]
}

resource "aws_api_gateway_integration" "accreditation_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.accreditation_resource.id
  http_method             = aws_api_gateway_method.accreditation_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.accreditation_handler.invoke_arn
}

resource "aws_api_gateway_method" "card_transaction_method" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.card_transactions_resource.id
  http_method      = "GET"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.bf_integration_access_authorizer.id
  api_key_required = true

  request_parameters = {
    "method.request.header.x-api-key"       = true
    "method.request.querystring.DataInicio" = true
    "method.request.querystring.DataFinal"  = true
    "method.request.querystring.NSU"        = true
  }

  depends_on = [
    aws_api_gateway_authorizer.bf_integration_access_authorizer
  ]
}

resource "aws_api_gateway_method_response" "card_transaction_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.card_transactions_resource.id
  http_method = aws_api_gateway_method.card_transaction_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }

  response_models = {
    "application/json" = aws_api_gateway_model.card_transaction_response_success_model.name
  }
}

resource "aws_api_gateway_method_response" "card_transaction_response_400" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.card_transactions_resource.id
  http_method = aws_api_gateway_method.card_transaction_method.http_method
  status_code = "400"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }

  response_models = {
    "application/json" = aws_api_gateway_model.card_transaction_response_failure_model.name
  }
}

resource "aws_api_gateway_integration" "card_transaction_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.card_transactions_resource.id
  http_method             = aws_api_gateway_method.card_transaction_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_transactions_handler.invoke_arn

  request_parameters = {
    "integration.request.header.x-api-key"       = "method.request.header.x-api-key"
    "integration.request.querystring.DataInicio" = "method.request.querystring.DataInicio"
    "integration.request.querystring.DataFinal"  = "method.request.querystring.DataFinal"
    "integration.request.querystring.NSU"        = "method.request.querystring.NSU"
  }

  depends_on = [
    aws_api_gateway_method_response.card_transaction_response_200,
    aws_api_gateway_method_response.card_transaction_response_400
  ]
}

resource "aws_api_gateway_integration_response" "card_transaction_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.card_transactions_resource.id
  http_method = aws_api_gateway_method.card_transaction_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.card_transaction_integration
  ]
}

resource "aws_api_gateway_integration_response" "card_transaction_integration_response_400" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.card_transactions_resource.id
  http_method       = aws_api_gateway_method.card_transaction_method.http_method
  status_code       = "400"
  selection_pattern = ".*\"ret_cod\":5.*"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.card_transaction_integration
  ]
}

resource "aws_api_gateway_resource" "exchange_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "exchange"
}

resource "aws_api_gateway_resource" "get_exchange_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.exchange_resource.id
  path_part   = "list"
}

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

resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name     = "api-${var.environment}.bemfacil.com.br"
  certificate_arn = "arn:aws:acm:us-east-1:343236792564:certificate/6f94b2f7-7469-4bd5-b11a-65c4d9ef26d5"
}

resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
}


resource "aws_api_gateway_resource" "vigilante_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "vigilante"
}

resource "aws_api_gateway_resource" "search_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.vigilante_resource.id
  path_part   = "search"
}

resource "aws_api_gateway_method" "search_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.search_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.bf_integration_access_authorizer.id


  depends_on = [
    aws_api_gateway_authorizer.bf_integration_access_authorizer
  ]
}

resource "aws_api_gateway_integration" "search_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.search_resource.id
  http_method             = aws_api_gateway_method.search_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.watchman_handler.invoke_arn



  depends_on = [
    aws_api_gateway_method.search_method
  ]
}


resource "aws_api_gateway_method_response" "search_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.search_resource.id
  http_method = aws_api_gateway_method.search_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }

}

resource "aws_api_gateway_integration_response" "search_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.search_resource.id
  http_method = aws_api_gateway_method.search_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }


  depends_on = [
    aws_api_gateway_integration.search_integration
  ]
}


resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_method.card_transaction_method,
    aws_api_gateway_integration.card_transaction_integration,
    aws_api_gateway_method.accreditation_method,
    aws_api_gateway_integration.accreditation_integration,
    aws_api_gateway_method.auth_method,
    aws_api_gateway_integration.auth_integration,
    aws_api_gateway_method.get_exchange_method,
    aws_api_gateway_integration.get_exchange_integration,
    aws_api_gateway_method.search_method,
    aws_api_gateway_integration.search_integration,
    aws_api_gateway_method_response.search_response_200,
    aws_api_gateway_integration_response.search_integration_response_200
  ]
}
