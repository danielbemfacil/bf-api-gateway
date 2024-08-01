import boto3
import json
import logging
import os

logger = logging.getLogger(__name__)

def lambda_handler(event, context):
    logger.info('Init')
    client = boto3.client('cognito-idp')
    
    body = json.loads(event['body'])
    username = body['username']
    password = body['password']
    client_id = os.environ['COGNITO_CLIENT_ID']
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    logger.info('Init 2')
    try:
        client.admin_set_user_password( 
                UserPoolId=user_pool_id,
                Username=username,
                Password=password,
                Permanent=True
            )
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        logger.info('response 1')
        
        return {
            'statusCode': 200,
            'body': json.dumps(response['AuthenticationResult'])
        }
    except client.exceptions.NotAuthorizedException as e:
        logger.info('NotAuthorizedException')
        return {
            'statusCode': 401,
            'body': json.dumps({'error': 'Unauthorized'})
        }
    except client.exceptions.UserNotFoundException as e:
        logger.info('UserNotFoundException')
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'User not found'})
        }
    except Exception as e:
        logger.info('Exception')
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
