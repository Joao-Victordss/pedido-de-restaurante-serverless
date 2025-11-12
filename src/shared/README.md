# Shared - Código Compartilhado

Este diretório contém código compartilhado entre as Lambdas.

## Estrutura

```
src/shared/
├── __init__.py
├── validators.py         # Validações de entrada
├── constants.py          # Constantes do sistema
├── exceptions.py         # Exceções customizadas
├── pdf_generator.py      # Geração de PDFs
└── aws_clients.py        # Clientes AWS configurados
```

## Módulos

### validators.py

Funções de validação de dados de entrada:

```python
def validate_pedido(data):
    """Valida dados de um pedido."""
    if not data.get('cliente'):
        raise ValueError('Cliente é obrigatório')
    if not data.get('itens') or len(data['itens']) == 0:
        raise ValueError('Pelo menos um item é obrigatório')
    if not isinstance(data.get('mesa'), int) or data['mesa'] <= 0:
        raise ValueError('Mesa deve ser um número maior que zero')
    return True

def validate_status(status):
    """Valida status de pedido."""
    valid_statuses = ['pendente', 'em_preparo', 'pronto', 'entregue', 'cancelado']
    if status not in valid_statuses:
        raise ValueError(f'Status inválido. Deve ser um de: {valid_statuses}')
    return True
```

### constants.py

Constantes do sistema:

```python
# Status de pedidos
STATUS_PENDENTE = 'pendente'
STATUS_EM_PREPARO = 'em_preparo'
STATUS_PRONTO = 'pronto'
STATUS_ENTREGUE = 'entregue'
STATUS_CANCELADO = 'cancelado'

# Configurações DynamoDB
DYNAMODB_TABLE = 'Pedidos'
DYNAMODB_PK = 'id'

# Configurações SQS
SQS_QUEUE_NAME = 'pedidos-queue'

# Configurações S3
S3_BUCKET = 'pedidos-comprovantes'
S3_PREFIX_COMPROVANTES = 'comprovantes/'

# Configurações SNS
SNS_TOPIC_NAME = 'PedidosConcluidos'
```

### exceptions.py

Exceções customizadas:

```python
class PedidoError(Exception):
    """Erro base para operações de pedido."""
    pass

class PedidoNotFoundError(PedidoError):
    """Pedido não encontrado."""
    pass

class PedidoValidationError(PedidoError):
    """Erro de validação de pedido."""
    pass

class PedidoProcessingError(PedidoError):
    """Erro ao processar pedido."""
    pass
```

### pdf_generator.py

Geração de PDFs de comprovantes:

```python
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from datetime import datetime

def generate_comprovante_pdf(pedido):
    """Gera PDF do comprovante do pedido."""
    pdf_path = f"/tmp/{pedido['id']}-comprovante.pdf"
    
    c = canvas.Canvas(pdf_path, pagesize=A4)
    width, height = A4
    
    # Cabeçalho
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, height - 50, "RESTAURANTE SERVERLESS")
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 70, "Comprovante de Pedido")
    
    # Dados do pedido
    c.setFont("Helvetica-Bold", 10)
    c.drawString(50, height - 100, f"Pedido: {pedido['id']}")
    c.drawString(50, height - 120, f"Cliente: {pedido['cliente']}")
    c.drawString(50, height - 140, f"Mesa: {pedido['mesa']}")
    c.drawString(50, height - 160, f"Status: {pedido['status']}")
    c.drawString(50, height - 180, f"Data: {pedido['timestamp']}")
    
    # Itens
    c.drawString(50, height - 210, "Itens:")
    y = height - 230
    for i, item in enumerate(pedido['itens'], 1):
        c.setFont("Helvetica", 10)
        c.drawString(70, y, f"{i}. {item}")
        y -= 20
    
    # Rodapé
    c.setFont("Helvetica-Oblique", 8)
    c.drawString(50, 50, f"Gerado em: {datetime.now().isoformat()}")
    
    c.save()
    return pdf_path
```

### aws_clients.py

Clientes AWS configurados:

```python
import boto3
import os

# Detectar ambiente (LocalStack ou AWS)
is_localstack = os.getenv('AWS_ENDPOINT_URL') is not None
endpoint_url = 'http://localhost:4566' if is_localstack else None

# Clientes AWS
dynamodb = boto3.resource(
    'dynamodb',
    endpoint_url=endpoint_url,
    region_name='us-east-1'
)

sqs = boto3.client(
    'sqs',
    endpoint_url=endpoint_url,
    region_name='us-east-1'
)

s3 = boto3.client(
    's3',
    endpoint_url=endpoint_url,
    region_name='us-east-1'
)

sns = boto3.client(
    'sns',
    endpoint_url=endpoint_url,
    region_name='us-east-1'
)
```

## Uso nas Lambdas

```python
# Em criar-pedido/index.py
from shared.validators import validate_pedido
from shared.constants import STATUS_PENDENTE
from shared.aws_clients import dynamodb, sqs

def handler(event, context):
    data = json.loads(event['body'])
    validate_pedido(data)  # Validar entrada
    # ... resto do código
```

```python
# Em processar-pedido/index.py
from shared.pdf_generator import generate_comprovante_pdf
from shared.aws_clients import s3, sns
from shared.constants import S3_BUCKET

def handler(event, context):
    # Gerar PDF
    pdf_path = generate_comprovante_pdf(pedido)
    
    # Upload no S3
    s3.upload_file(pdf_path, S3_BUCKET, key)
    # ... resto do código
```

## Testes

```python
# tests/unit/test_validators.py
import pytest
from shared.validators import validate_pedido

def test_validate_pedido_success():
    data = {
        'cliente': 'João Silva',
        'itens': ['Pizza'],
        'mesa': 5
    }
    assert validate_pedido(data) == True

def test_validate_pedido_missing_cliente():
    data = {'itens': ['Pizza'], 'mesa': 5}
    with pytest.raises(ValueError):
        validate_pedido(data)
```

## Dependências

```
boto3>=1.34.0
reportlab>=4.0.0
```

## Próximos Passos

1. ⏳ Implementar validators.py
2. ⏳ Implementar constants.py
3. ⏳ Implementar exceptions.py
4. ⏳ Implementar pdf_generator.py
5. ⏳ Implementar aws_clients.py
6. ⏳ Criar testes unitários
