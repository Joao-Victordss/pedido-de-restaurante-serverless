import json
import os
import boto3
from datetime import datetime

# Configuração para LocalStack
# Se estiver rodando dentro do container LocalStack, usar o hostname interno
# Se estiver testando localmente, usar localhost
LOCALSTACK_HOSTNAME = os.getenv('LOCALSTACK_HOSTNAME', 'localhost')
LOCALSTACK_ENDPOINT = f'http://{LOCALSTACK_HOSTNAME}:4566'
AWS_ENDPOINT_URL = os.getenv('AWS_ENDPOINT_URL', LOCALSTACK_ENDPOINT)

DYNAMODB_TABLE = os.getenv('DYNAMODB_TABLE', 'Pedidos')
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL', f'http://{LOCALSTACK_HOSTNAME}:4566/000000000000/pedidos-queue')

print(f"Configuração: endpoint={AWS_ENDPOINT_URL}, table={DYNAMODB_TABLE}, queue={SQS_QUEUE_URL}")

# Clientes AWS - usar client em vez de resource para melhor compatibilidade
dynamodb_client = boto3.client(
    'dynamodb',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)
sqs = boto3.client(
    'sqs',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)


def validate_pedido(data):
    """Valida os dados do pedido."""
    errors = []
    
    # Validar cliente
    if not data.get('cliente'):
        errors.append('Campo "cliente" é obrigatório')
    elif len(data['cliente'].strip()) < 3:
        errors.append('Campo "cliente" deve ter pelo menos 3 caracteres')
    
    # Validar itens
    if not data.get('itens'):
        errors.append('Campo "itens" é obrigatório')
    elif not isinstance(data['itens'], list):
        errors.append('Campo "itens" deve ser uma lista')
    elif len(data['itens']) == 0:
        errors.append('Deve haver pelo menos um item no pedido')
    
    # Validar mesa
    if not data.get('mesa'):
        errors.append('Campo "mesa" é obrigatório')
    elif not isinstance(data['mesa'], int):
        errors.append('Campo "mesa" deve ser um número inteiro')
    elif data['mesa'] <= 0:
        errors.append('Campo "mesa" deve ser maior que zero')
    
    return errors


def create_response(status_code, body):
    """Cria resposta HTTP padronizada."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(body, ensure_ascii=False)
    }


def handler(event, context):
    """
    Lambda handler para criar pedido.
    
    Fluxo:
    1. Valida payload
    2. Gera ID único para o pedido
    3. Salva no DynamoDB
    4. Envia mensagem para SQS
    5. Retorna resposta HTTP
    """
    try:
        # Parse do body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        print(f"Payload recebido: {json.dumps(body)}")
        
        # Validar dados
        errors = validate_pedido(body)
        if errors:
            return create_response(400, {
                'error': 'Dados inválidos',
                'details': errors
            })
        
        # Gerar ID do pedido (timestamp + ms)
        timestamp = datetime.utcnow()
        pedido_id = f"pedido-{timestamp.strftime('%Y%m%d%H%M%S')}"
        
        # Montar item do pedido
        pedido = {
            'id': pedido_id,
            'cliente': body['cliente'].strip(),
            'itens': body['itens'],
            'mesa': body['mesa'],
            'status': 'pendente',
            'timestamp': timestamp.isoformat()
        }
        
        print(f"Criando pedido: {pedido_id}")
        
        # Salvar no DynamoDB usando client
        dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE,
            Item={
                'id': {'S': pedido_id},
                'cliente': {'S': pedido['cliente']},
                'itens': {'L': [{'S': item} for item in pedido['itens']]},
                'mesa': {'N': str(pedido['mesa'])},
                'status': {'S': pedido['status']},
                'timestamp': {'S': pedido['timestamp']}
            }
        )
        print(f"Pedido salvo no DynamoDB: {pedido_id}")
        
        # Enviar mensagem para SQS
        sqs_message = {
            'pedidoId': pedido_id,
            'cliente': pedido['cliente'],
            'itens': pedido['itens'],
            'mesa': pedido['mesa'],
            'timestamp': pedido['timestamp']
        }
        
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(sqs_message, ensure_ascii=False),
            MessageAttributes={
                'pedidoId': {
                    'StringValue': pedido_id,
                    'DataType': 'String'
                },
                'status': {
                    'StringValue': 'pendente',
                    'DataType': 'String'
                }
            }
        )
        print(f"Mensagem enviada para SQS: {pedido_id}")
        
        # Resposta de sucesso
        return create_response(201, {
            'message': 'Pedido criado com sucesso',
            'pedidoId': pedido_id,
            'status': 'pendente',
            'timestamp': pedido['timestamp']
        })
        
    except json.JSONDecodeError as e:
        print(f"Erro ao parsear JSON: {str(e)}")
        return create_response(400, {
            'error': 'JSON inválido',
            'details': str(e)
        })
    
    except Exception as e:
        print(f"Erro inesperado: {str(e)}")
        return create_response(500, {
            'error': 'Erro interno do servidor',
            'details': str(e)
        })
