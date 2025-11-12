import json
import os
import boto3
from datetime import datetime
from io import BytesIO
from fpdf import FPDF

# Configuração para LocalStack
LOCALSTACK_HOSTNAME = os.getenv('LOCALSTACK_HOSTNAME', 'localhost')
LOCALSTACK_ENDPOINT = f'http://{LOCALSTACK_HOSTNAME}:4566'
AWS_ENDPOINT_URL = os.getenv('AWS_ENDPOINT_URL', LOCALSTACK_ENDPOINT)

DYNAMODB_TABLE = os.getenv('DYNAMODB_TABLE', 'Pedidos')
S3_BUCKET = os.getenv('S3_BUCKET', 'pedidos-comprovantes')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN', 'arn:aws:sns:us-east-1:000000000000:PedidosConcluidos')

print(f"Configuração: endpoint={AWS_ENDPOINT_URL}, table={DYNAMODB_TABLE}, bucket={S3_BUCKET}, topic={SNS_TOPIC_ARN}")

# Clientes AWS
dynamodb_client = boto3.client(
    'dynamodb',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)

s3_client = boto3.client(
    's3',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)

sns_client = boto3.client(
    'sns',
    endpoint_url=AWS_ENDPOINT_URL,
    region_name='us-east-1'
)


def generate_pdf_content(pedido_data):
    """
    Gera conteúdo do PDF usando FPDF2.
    Mantém o mesmo layout de texto, mas gera um PDF real.
    """
    pedido_id = pedido_data.get('pedidoId')
    cliente = pedido_data.get('cliente')
    mesa = pedido_data.get('mesa')
    itens = pedido_data.get('itens', [])
    timestamp = pedido_data.get('timestamp')
    
    # Criar PDF
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    # Usar fonte Courier para estilo de comprovante
    pdf.set_font("Courier", size=10)
    
    # Cabeçalho
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 5, "=" * 70, ln=True, align='C')
    pdf.ln(2)
    pdf.set_font("Courier", "B", 16)
    pdf.cell(0, 8, "COMPROVANTE DE PEDIDO", ln=True, align='C')
    pdf.ln(2)
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 5, "=" * 70, ln=True, align='C')
    pdf.ln(8)
    
    # Informações do pedido
    pdf.set_font("Courier", "", 10)
    pdf.cell(0, 6, f"Pedido ID: {pedido_id}", ln=True)
    pdf.cell(0, 6, f"Cliente: {cliente}", ln=True)
    pdf.cell(0, 6, f"Mesa: {mesa}", ln=True)
    pdf.cell(0, 6, f"Data/Hora: {timestamp}", ln=True)
    pdf.ln(8)
    
    # Separador
    pdf.cell(0, 5, "-" * 70, ln=True, align='C')
    pdf.ln(2)
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 6, "ITENS DO PEDIDO", ln=True, align='C')
    pdf.ln(2)
    pdf.set_font("Courier", "", 10)
    pdf.cell(0, 5, "-" * 70, ln=True, align='C')
    pdf.ln(6)
    
    # Lista de itens
    for idx, item in enumerate(itens, 1):
        pdf.cell(0, 6, f"{idx}. {item}", ln=True)
    
    pdf.ln(6)
    
    # Separador
    pdf.cell(0, 5, "-" * 70, ln=True, align='C')
    pdf.ln(6)
    
    # Status
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 6, "Status: PROCESSADO", ln=True)
    pdf.set_font("Courier", "", 10)
    pdf.cell(0, 6, "Comprovante gerado automaticamente", ln=True)
    pdf.ln(8)
    
    # Rodapé
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 5, "=" * 70, ln=True, align='C')
    pdf.ln(2)
    pdf.cell(0, 6, "Obrigado pela preferencia!", ln=True, align='C')
    pdf.ln(2)
    pdf.cell(0, 5, "=" * 70, ln=True, align='C')
    
    # Retornar bytes do PDF
    return pdf.output()


def update_pedido_status(pedido_id, status, s3_key=None):
    """Atualiza o status do pedido no DynamoDB."""
    update_expression = "SET #status = :status, #updated_at = :updated_at"
    expression_values = {
        ':status': {'S': status},
        ':updated_at': {'S': datetime.utcnow().isoformat()}
    }
    expression_names = {
        '#status': 'status',
        '#updated_at': 'updated_at'
    }
    
    if s3_key:
        update_expression += ", #comprovante_url = :comprovante_url"
        expression_values[':comprovante_url'] = {'S': s3_key}
        expression_names['#comprovante_url'] = 'comprovante_url'
    
    dynamodb_client.update_item(
        TableName=DYNAMODB_TABLE,
        Key={'id': {'S': pedido_id}},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expression_values,
        ExpressionAttributeNames=expression_names
    )


def publish_notification(pedido_data, s3_key):
    """Publica notificação no SNS sobre pedido processado."""
    message = {
        'pedidoId': pedido_data.get('pedidoId'),
        'cliente': pedido_data.get('cliente'),
        'mesa': pedido_data.get('mesa'),
        'status': 'processado',
        'comprovante': s3_key,
        'timestamp': datetime.utcnow().isoformat()
    }
    
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps(message, ensure_ascii=False),
        Subject=f"Pedido Processado: {pedido_data.get('pedidoId')}",
        MessageAttributes={
            'pedidoId': {
                'StringValue': pedido_data.get('pedidoId'),
                'DataType': 'String'
            },
            'status': {
                'StringValue': 'processado',
                'DataType': 'String'
            }
        }
    )


def process_pedido(pedido_data):
    """
    Processa um pedido:
    1. Gera PDF
    2. Upload para S3
    3. Atualiza status no DynamoDB
    4. Notifica via SNS
    """
    pedido_id = pedido_data.get('pedidoId')
    print(f"Processando pedido: {pedido_id}")
    
    try:
        # 1. Gerar PDF
        print(f"Gerando PDF para {pedido_id}...")
        pdf_content = generate_pdf_content(pedido_data)
        
        # 2. Upload para S3
        s3_key = f"comprovantes/{pedido_id}.pdf"
        print(f"Fazendo upload para S3: {s3_key}...")
        
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=pdf_content,
            ContentType='application/pdf',
            Metadata={
                'pedido-id': pedido_id,
                'mesa': str(pedido_data.get('mesa', '')),
                'generated-at': datetime.utcnow().isoformat()
            }
        )
        print(f"PDF salvo no S3: {s3_key}")
        
        # 3. Atualizar status no DynamoDB
        print(f"Atualizando status no DynamoDB para {pedido_id}...")
        update_pedido_status(pedido_id, 'processado', s3_key)
        print(f"Status atualizado: processado")
        
        # 4. Notificar via SNS
        print(f"Publicando notificação no SNS para {pedido_id}...")
        publish_notification(pedido_data, s3_key)
        print(f"Notificação enviada para SNS")
        
        return {
            'success': True,
            'pedidoId': pedido_id,
            's3Key': s3_key
        }
        
    except Exception as e:
        print(f"Erro ao processar pedido {pedido_id}: {str(e)}")
        # Atualizar status para erro
        try:
            update_pedido_status(pedido_id, 'erro')
        except:
            pass
        raise


def handler(event, context):
    """
    Lambda handler para processar pedidos da SQS.
    
    Fluxo:
    1. Recebe mensagens da SQS (batch)
    2. Para cada mensagem:
       - Gera PDF do comprovante
       - Upload para S3
       - Atualiza status no DynamoDB
       - Publica notificação no SNS
    3. Retorna resultado do processamento
    """
    print(f"Evento recebido: {json.dumps(event)}")
    
    results = {
        'batchItemFailures': []
    }
    
    # Processar cada record do SQS
    for record in event.get('Records', []):
        message_id = record.get('messageId')
        receipt_handle = record.get('receiptHandle')
        
        try:
            # Parse da mensagem
            body = json.loads(record.get('body', '{}'))
            print(f"Processando mensagem {message_id}: {json.dumps(body)}")
            
            # Processar pedido
            result = process_pedido(body)
            print(f"✅ Pedido processado com sucesso: {result['pedidoId']}")
            
        except json.JSONDecodeError as e:
            print(f"❌ Erro ao parsear mensagem {message_id}: {str(e)}")
            # Adicionar à lista de falhas para reprocessamento
            results['batchItemFailures'].append({
                'itemIdentifier': message_id
            })
            
        except Exception as e:
            print(f"❌ Erro ao processar mensagem {message_id}: {str(e)}")
            # Adicionar à lista de falhas para reprocessamento
            results['batchItemFailures'].append({
                'itemIdentifier': message_id
            })
    
    print(f"Processamento concluído. Falhas: {len(results['batchItemFailures'])}")
    return results
