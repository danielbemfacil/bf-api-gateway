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

        url = "http://10.0.0.210:8084/search?q=John+Doe&name=Jane+Smith&address=123+83rd+Ave&city=USA&state=USA&providence=USA&zip=USA&country=USA&altName=Jane+Smith&id=10517860&minMatch=0.95&limit=25&sdnType=individual&program=SDGT"
        response = requests.get(
            f"{url}",
            headers={'accept': 'application/json', 'x-request-id': '94c825ee'},
        )
        logger.info('Get watchman completed')
        return {
            'statusCode': 200,
            'body': json.dumps(response.json())
        }
        

    except Exception as e:
        logger.error(f'erro encontrado no handler: {str(e)}')
        return {
            'statusCode': 500,
            'body': str(e)
        }