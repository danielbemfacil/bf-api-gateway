import json
import os
import requests
import jwt
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('Inicio do evento de cotacoes')

    try:
        token = event['headers']['Authorization'].replace(' Bearer ', '')
        token = token.replace('Bearer ', '')

        logger.info('Inicio da decodificacao do token')
        # Valide o token JWT e extraia os dados necessários
        decoded_token = jwt.decode(token, options={"verify_signature": False}, algorithms=["HS256"])
        est_cpf_cnpj = decoded_token.get('custom:EstCpfCnpj')

        logger.info(f'fim da decodificacao do token, cliente identificado: {est_cpf_cnpj}')

        url = "https://webservice.enfoque.com.br/wsBemFacil/BemFacil.asmx"
        response = requests.post(
            f"{url}/getCotacoes",
            headers={'Content-Type': 'application/x-www-form-urlencoded'},
            data="login=BemFacil&senha=!%40%23BF2023"
        )
        logger.info('Get cotacoes completed')
        return {
            'statusCode': response.status_code,
            'body': json.dumps(response.json())
        }
        

    except Exception as e:
        logger.error(f'erro encontrato no handler: {str(e)}')
        return {
            'statusCode': 500,
            'body': str(e)
        }