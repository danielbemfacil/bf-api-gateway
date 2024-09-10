import json
import os
import requests
import jwt
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('Inicio do evento do retaguarda - credenciamento')
    try:
        token: str = event['headers']['Authorization'].replace(' Bearer ', '')
        token: str = token.replace('Bearer ', '')
        gx_client_id: str = os.environ['GX_CLIENT_ID']


        logger.info('Inicio da decodificacao do token')
        # Valide o token JWT e extraia os dados necessários
        decoded_token: dict = jwt.decode(token, options={"verify_signature": False}, algorithms=["HS256"])

        
        api_key: str = decoded_token.get('custom:ApiKey')
        est_cpf_cnpj: str = decoded_token.get('custom:EstCpfCnpj')

        logger.info(f'fim da decodificacao do token, cliente identificado: {est_cpf_cnpj}')

        body_parameters: dict = event.get('body', {})
        
        
        logger.info(f'Pegou o body {json.dumps(body_parameters)}')

        if not body_parameters:
            return {
            'statusCode': 400,
            'body': json.dumps({
                "ret_cod": 5,
                "ret_dsc": "Dados para credenciamento inválidos"
            })
            }

        # Construa o payload para a API de retaguarda
        payload_api_key: dict = {
            "ApiKey": api_key,
        }
        body_parameters = json.loads(body_parameters)
        payload: dict = {
            **payload_api_key, **body_parameters
        }

        
                
        logger.info(f'Inicio do request para o retaguarda')
        logger.info(f'Pegou o payload {json.dumps(payload)}')
        headers = {
            'Content-Type': 'application/json',
            'Cookie': f'GX_CLIENT_ID={gx_client_id}'
        }


        response = requests.post(
            'https://sistema.qa.bemfacil.digital/bemfacilev15/rest/api_cadastrar_estabelecimento',
            headers=headers,
            data=json.dumps(payload),
            verify=False
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
        logger.info(response.json())
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
#                "CnpjCpf":"03688014000138",
#    "PessoaFisicaJuridica":"J",
#    "Credenciador":"31648992000191",
#    "RazaoSocial":"EMPRESA TESTE",
#    "NomeFantasia":"EMPRESA TESTE",
#    "Mcc":"5651",
#    "Cnae":"4781400",
#    "ResponsavelNome":"TESTE SANTOS SILVA",
#    "Email":"jessicasouzaduda352@gmail.com",
#    "DataAbertura":"01/01/2024",
#    "Endereco":"AVENIDA MAMEDE PAES MENDONCA BOX 40 E 41",
#    "EnderecoNumero":"41",
#    "EnderecoComplemento":"",
#    "EnderecoBairro":"CENTRO",
#    "EnderecoCidade":"ARACAJU",
#    "EnderecoUF":"SE",
#    "EnderecoCep":"49010",
#    "EnderecoCepCpl":"620",
#    "TelefoneResDDD":"",
#    "TelefoneResNumero":"",
#    "TelefoneCelDDD":"",
#    "TelefoneCelNumero":"",
#    "TelefoneCmlDDD":"79",
#    "TelefoneCmlNumero":"988222174",
#    "Departamento":"0",
#    "TabVenda":"648",
#    "Socios":[
#       {
#          "Ind":"U",
#          "SocNumSeq":1,
#          "SocNomSoc":"Socio 1",
#          "SocCep":11215,
#          "SocCepCpl":110,
#          "SocUF":"SP",
#          "SocMun":"MUNICIPIO",
#          "SocBai":"BAIRRO",
#          "SocCplEnd":"APTO XPTO",
#          "SocNumEnd":"123",
#          "SocLog":"LOGRADOURO",
#          "SocDtaNsc":"29/10/1989",
#          "SocCPF":"12312312312",
#          "SocDddTel":11,
#          "SocNumTel":987121212
#       },
#       {
#          "Ind":"I",
#          "SocNumSeq":2,
#          "SocNomSoc":"Socio 2",
#          "SocCepCpl":"110",
#          "SocCep":11215,
#          "SocUF":"SP",
#          "SocMun":"MUNICIPIO",
#          "SocBai":"BAIRRO",
#          "SocCplEnd":"APTO XPTO",
#          "SocNumEnd":"123",
#          "SocLog":"LOGRADOURO",
#          "SocDtaNsc":"29/10/1989",
#          "SocCPF":"4324232423",
#          "SocDddTel":11,
#          "SocNumTel":987121212
#       }
#    ],
#    "Documentos":[
#       {
#          "Ind":"I",
#          "EstCod":"15275",
#          "EstDocTipo":"3",
#          "EstDocNumero":"03688014000138",
#          "EstDocObservacao":"",
#          "EstDocImagemDocumento":"",
#          "EstDocSeq":""
#       }
#    ],
#    "ContasBancarias":[
#       {
#          "ContaBancariaInd":"I",
#          "ContaBancariaBanCod":"047",
#          "ContaBancariaTipoConta":"J",
#          "ContaBancariaTipoOpe":"047",
#          "ContaBancariaDocumento":"03688014000138",
#          "ContaBancariaAgencia":"14",
#          "ContaBancariaAgenciaDigito":"1",
#          "ContaBancariaNumContaCorrente":"31312622",
#          "ContaBancariaDigitoContaCorrente":"1",
#          "ContaBancariaContaPrincipal":"S",
#          "ContaBancariaTipoChavePix":"03",
#          "ContaBancariaChavePix":"03688014000138"
#       }
#    ]
#             },
#         'queryStringParameters':  {
#             'DataInicio': '20240404',
#             'DataFinal': '20240404'
#         }
#          },
#         None
#     )
#     # logger.info('OI')