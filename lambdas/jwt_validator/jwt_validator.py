import json
import jwt

def lambda_handler(event, context):
    token = event['authorizationToken']
    # Valide o token JWT e extraia os dados necessários
    decoded_token = jwt.decode(token, options={"verify_signature": False})
    api_key = decoded_token.get('ApiKey')
    est_cpf_cnpj = decoded_token.get('EstCpfCnpj')

    return {
        'principalId': 'user',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': 'Allow',
                    'Resource': event['methodArn']
                }
            ]
        },
        'context': {
            'ApiKey': api_key,
            'EstCpfCnpj': est_cpf_cnpj
        }
    }
