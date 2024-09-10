import json
import os
import requests
import jwt
import logging
from urllib.parse import urlencode  # Para construir a query string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('Inicio do evento de cotacoes')

    try:
        # Extrair o token do cabeçalho e decodificá-lo
        token = event['headers']['Authorization'].replace(' Bearer ', '')
        token = token.replace('Bearer ', '')

        logger.info('Inicio da decodificacao do token')
        decoded_token = jwt.decode(token, options={"verify_signature": False}, algorithms=["HS256"])
        est_cpf_cnpj = decoded_token.get('custom:EstCpfCnpj')

        logger.info(f'fim da decodificacao do token, cliente identificado: {est_cpf_cnpj}')

        # Extrair o corpo da requisição
        if 'body' in event:
            request_body = json.loads(event['body'])  # Decodificar JSON do corpo

        # Montar a query string com os dados do corpo
        query_params = urlencode(request_body)  # Converte o dicionário do body para query string

        # Definir a URL da requisição com a query string
        url = f"http://10.0.0.210:8084/search?{query_params}"

        # Fazer a requisição GET com a URL completa
        response = requests.get(
            url,
            headers={'accept': 'application/json', 'x-request-id': '94c825ee'}
        )

        logger.info('Get request to watchman completed')
        
        return {
            'statusCode': 200,
            'body': json.dumps(response.json())
        }

    except Exception as e:
        logger.error(f'Erro encontrado no handler: {str(e)}')
        return {
            'statusCode': 500,
            'body': str(e)
        }
