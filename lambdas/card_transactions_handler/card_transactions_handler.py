import json
import os
import requests
import jwt
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('Inicio do evento do retaguarda transacoes')
    try:
        token = event['headers']['Authorization'].replace(' Bearer ', '')
        token = token.replace('Bearer ', '')
        gx_client_id = os.environ['GX_CLIENT_ID']


        logger.info('Inicio da decodificacao do token')
        # Valide o token JWT e extraia os dados necessários
        decoded_token = jwt.decode(token, options={"verify_signature": False}, algorithms=["HS256"])
        api_key = decoded_token.get('custom:ApiKey')
        est_cpf_cnpj = decoded_token.get('custom:EstCpfCnpj')

        logger.info(f'fim da decodificacao do token, cliente identificado: {est_cpf_cnpj}')

        query_string_parameters = event.get('queryStringParameters', {})
        
        logger.info(f'Pegou o querystring {json.dumps(query_string_parameters)}')

        if not query_string_parameters:
            return {
            'statusCode': 400,
            'body': json.dumps({
                "ret_cod": 5,
                "ret_dsc": "Dados para consulta inválidos"
            })
            }

        # Construa o payload para a API de retaguarda
        payload = {
            "ApiKey": api_key,
            "EstCpfCnpj": est_cpf_cnpj,
            "DataInicio": query_string_parameters.get('DataInicio', ''),
            "DataFinal": query_string_parameters.get('DataFinal', ''),
            "NSU": query_string_parameters.get('NSU', '')
        }
                
        logger.info(f'Inicio do request para o retaguarda')

        headers = {
            'Content-Type': 'application/json',
            'Cookie': f'GX_CLIENT_ID={gx_client_id}'
        }


        response = requests.post(
            'https://sistema.bemfacil.digital/bemfacil/rest/api_transacoes_realtime',
            headers=headers,
            data=json.dumps(payload)
        )

        logger.info(f'Evento finalizado')
        ret_cod = response.json().get('ret_cod', 0)
        if ret_cod:
            if ret_cod == 6:
                logger.error('Registro não encontrado')
                return {
                    'statusCode': 404,
                    'body': json.dumps(response.json())
                }
            logger.error(f'Erro encontrado no retaguarda {json.dumps(response.json())}')
            return {
                'statusCode': 400,
                'body': json.dumps(response.json())
            }    
        logger.info(f'Consulta realizada com sucesso')
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
    
# if __name__ == '__main__':
#     lambda_handler(
#         {'headers': {'Authorization': ' Bearer eyJraWQiOiIwVE9mMHhmYm9Jb0FBbFZ1QmNRbjhZUDZjd2Q1WnVERXpOVkFyZ3c1Z3NjPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJjNDg4MjRiOC05MGYxLTcwOGItZWQ5OS00OWNiNzVlY2E2NjEiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV8yZHliNFpYVkgiLCJjb2duaXRvOnVzZXJuYW1lIjoiZGFuaWVsLm5hc2NpbWVudG9AYmVtZmFjaWwuY29tLmJyIiwib3JpZ2luX2p0aSI6ImZkMjRiY2I4LWY0N2MtNGNkYy1hYjYxLTI1ZGY3ODU1MDE0NSIsImF1ZCI6IjRqOTltcXZiMmhxcTV2ZDhlbzNibjliYXFpIiwiZXZlbnRfaWQiOiJiMzI3YzI1NS0zZDNkLTQzNWYtYjEwYy1iODg2MDgzZTgwNGMiLCJjdXN0b206QXBpS2V5IjoiN2JmNmJlYjgtODU4OC00MjY2LWE5ZjAtNjY5YjdjMzFjYjRmIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3MTkzNDI5ODYsImV4cCI6MTcxOTM0NjU4NiwiaWF0IjoxNzE5MzQyOTg2LCJqdGkiOiIzNGVjOTA4MC0xZTEzLTRmNzItOTM0OC0yNWY4ZTBlMmY4NGUiLCJjdXN0b206RXN0Q3BmQ25waiI6IjA5MTA0MzczNDMwIn0.RCGfe4s9q6FJEilpRSAxExnMqtvxVJ7MjoBMZ6mroi7yqQdIumCXBQjK4ieFt4TLax7UuVaNoYgbtYoJnNpELfFk_n2dIbzEGj5itggGW0HpF0HpJMzaAzhDaH5_b09fNl4xOytfaY9V4fVrRm-pX-EfvtJxENuqAmjcANlliOD1X_vGwftwzCLHNVmYfq_AkJtFi7SQvVP5zlBrWSYxbfWUzvP7BXjZYeHZB5gTkCPPC6cJH8zGHTr-47eKr2ol5kJmEnRRK6MwDjYt3JMnuANNVJE55YQNqBMuirZJDmx0fd-AX1NK6xjCwYkDFZhWuK8mzyU95_HUvCjOQt_o7A'},
#          'body': {
#                 "DataInicio": "20240415",
#                 "DataFinal": "20240415",
#                 "NSU": "123123123"
#             },
#         'queryStringParameters':  {
#             'DataInicio': '20240404',
#             'DataFinal': '20240404'
#         }
#          },
#         None
#     )
#     # print('OI')