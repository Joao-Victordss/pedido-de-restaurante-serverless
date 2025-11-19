import json
import os
import boto3

# Configuração para LocalStack
LOCALSTACK_HOSTNAME = os.getenv('LOCALSTACK_HOSTNAME', 'localhost')
LOCALSTACK_ENDPOINT = f'http://{LOCALSTACK_HOSTNAME}:4566'
AWS_ENDPOINT_URL = os.getenv('AWS_ENDPOINT_URL', LOCALSTACK_ENDPOINT)

DYNAMODB_TABLE = os.getenv('DYNAMODB_TABLE', 'Pedidos')

print(f"Configuração: endpoint={AWS_ENDPOINT_URL}, table={DYNAMODB_TABLE}")

# Cliente DynamoDB
dynamodb_client = boto3.client(
    'dynamodb',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)


def create_response(status_code, body):
    """Cria resposta HTTP padronizada."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, OPTIONS'
        },
        'body': json.dumps(body, ensure_ascii=False)
    }


def parse_dynamodb_item(item):
    """Converte item do DynamoDB para formato simples."""
    pedido = {
        'id': item['id']['S'],
        'status': item.get('status', {}).get('S', ''),
        'timestamp': item.get('timestamp', {}).get('S', '')
    }
    
    # Campos opcionais
    if 'cliente' in item:
        pedido['cliente'] = item['cliente']['S']
    
    if 'mesa' in item:
        pedido['mesa'] = int(item['mesa']['N'])
    
    if 'itens' in item and 'L' in item['itens']:
        pedido['itens'] = [i.get('S', '') for i in item['itens']['L']]
    
    if 'comprovante_url' in item:
        pedido['comprovante_url'] = item['comprovante_url']['S']
    
    if 'updated_at' in item:
        pedido['updated_at'] = item['updated_at']['S']
    
    return pedido


def handler(event, context):
    """
    Lambda handler para listar ou buscar pedidos.
    
    Rotas suportadas:
    - GET /pedidos - Lista todos os pedidos
    - GET /pedidos/{id} - Busca pedido específico
    """
    try:
        print(f"Evento recebido: {json.dumps(event)}")
        
        # Extrair parâmetros
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        pedido_id = path_parameters.get('id')
        
        # GET /pedidos/{id} - Buscar pedido específico
        if pedido_id:
            print(f"Buscando pedido: {pedido_id}")
            
            response = dynamodb_client.get_item(
                TableName=DYNAMODB_TABLE,
                Key={'id': {'S': pedido_id}}
            )
            
            if 'Item' not in response:
                return create_response(404, {
                    'error': 'Pedido não encontrado',
                    'pedidoId': pedido_id
                })
            
            pedido = parse_dynamodb_item(response['Item'])
            print(f"Pedido encontrado: {pedido_id}")
            
            return create_response(200, pedido)
        
        # GET /pedidos - Listar todos os pedidos
        else:
            print("Listando todos os pedidos")
            
            # Parâmetros de paginação
            limit = int(query_parameters.get('limit', 50))
            
            # Parâmetro de filtro por status
            status_filter = query_parameters.get('status')
            
            # Scan DynamoDB - pegar TODOS os itens para ordenar corretamente
            scan_params = {
                'TableName': DYNAMODB_TABLE
            }
            
            if status_filter:
                scan_params['FilterExpression'] = '#status = :status'
                scan_params['ExpressionAttributeNames'] = {'#status': 'status'}
                scan_params['ExpressionAttributeValues'] = {':status': {'S': status_filter}}
            
            # Fazer scan completo (pode ter múltiplas páginas)
            all_items = []
            while True:
                response = dynamodb_client.scan(**scan_params)
                all_items.extend(response.get('Items', []))
                
                # Se não tem mais páginas, sair do loop
                if 'LastEvaluatedKey' not in response:
                    break
                    
                # Configurar para próxima página
                scan_params['ExclusiveStartKey'] = response['LastEvaluatedKey']
            
            # Parsear itens
            pedidos = [parse_dynamodb_item(item) for item in all_items]
            
            # Ordenar por timestamp (mais recente primeiro)
            pedidos.sort(key=lambda x: x['timestamp'], reverse=True)
            
            # Aplicar limite APÓS ordenar
            pedidos = pedidos[:limit]
            
            print(f"Encontrados {len(pedidos)} pedidos (ordenados por timestamp desc)")
            
            # Resposta
            result = {
                'pedidos': pedidos,
                'count': len(pedidos)
            }
            
            return create_response(200, result)
        
    except Exception as e:
        print(f"Erro: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return create_response(500, {
            'error': 'Erro interno do servidor',
            'details': str(e)
        })
