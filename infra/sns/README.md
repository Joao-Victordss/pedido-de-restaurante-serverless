# SNS - Notificações de Pedidos Concluídos

Tópico SNS para enviar notificações quando pedidos são concluídos.

## 📋 Configuração do Tópico

### Tópico: `PedidosConcluidos`

```yaml
Nome: PedidosConcluidos
Display Name: Notificacoes de Pedidos Concluidos
Região: us-east-1
Protocolos: Email, HTTP, SMS, SQS, Lambda
```

## 📨 Formato das Notificações

### Mensagem Simples:
```json
{
  "TopicArn": "arn:aws:sns:us-east-1:000000000000:PedidosConcluidos",
  "Message": "Novo pedido concluído: 12345",
  "Subject": "Pedido Pronto!"
}
```

### Mensagem Estruturada:
```json
{
  "TopicArn": "arn:aws:sns:us-east-1:000000000000:PedidosConcluidos",
  "Message": "Novo pedido concluído: pedido-20251111120000",
  "Subject": "Pedido Concluído - Detalhes",
  "Detalhes": {
    "pedidoId": "pedido-20251111120000",
    "cliente": "João Silva",
    "mesa": 5,
    "total": 43.00,
    "status": "concluido",
    "timestamp": "2025-11-11T12:00:00Z"
  }
}
```

## 🚀 Como Usar

### Criar o Tópico

**PowerShell:**
```powershell
.\infra\sns\create-topic-pedidos.ps1
```

**Bash:**
```bash
./infra/sns/create-topic-pedidos.sh
```

### Testar o Tópico

```powershell
.\infra\sns\test-topic-pedidos.ps1
```

O script de teste executa:
1. ✅ Publicação de mensagem simples
2. ✅ Publicação de mensagem estruturada (JSON)
3. ✅ Publicação com atributos de mensagem
4. ✅ Listagem de subscrições
5. ✅ Verificação de atributos do tópico

## 🔄 Fluxo de Notificação

```
Lambda Processar Pedido
         ↓
    Gera comprovante PDF
         ↓
    Salva no S3
         ↓
    Publica no SNS Topic
         ↓
  ┌─────────┴─────────┐
  ↓                   ↓
Email             HTTP Webhook
(Cozinha)         (Sistema Externo)
```

## 📊 Tipos de Subscrição

### 1. Email
- **Endpoint**: `cozinha@restaurante.com`
- **Uso**: Notificar equipe da cozinha
- **Confirmação**: Requer confirmação do destinatário (em produção)

### 2. HTTP/HTTPS
- **Endpoint**: `http://localhost:3000/webhook/pedidos`
- **Uso**: Integração com sistemas externos
- **Payload**: JSON com detalhes completos

### 3. SMS (opcional)
- **Endpoint**: Número de telefone
- **Uso**: Alertas críticos para gerente

### 4. SQS (opcional)
- **Endpoint**: ARN de fila SQS
- **Uso**: Processamento assíncrono adicional

### 5. Lambda (opcional)
- **Endpoint**: ARN de função Lambda
- **Uso**: Lógica personalizada de notificação

## 🔧 Comandos Úteis

### Publicar mensagem:

```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:000000000000:PedidosConcluidos \
  --subject "Pedido Pronto!" \
  --message "Pedido 12345 está pronto" \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Listar tópicos:

```bash
aws sns list-topics \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Listar subscrições:

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:000000000000:PedidosConcluidos \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Criar subscrição:

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:PedidosConcluidos \
  --protocol email \
  --notification-endpoint seu-email@exemplo.com \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Deletar subscrição:

```bash
aws sns unsubscribe \
  --subscription-arn <subscription-arn> \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Publicar com atributos:

```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:000000000000:PedidosConcluidos \
  --subject "Pedido Express!" \
  --message "Pedido prioritário pronto" \
  --message-attributes '{"tipo":{"DataType":"String","StringValue":"express"}}' \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

## 📱 Exemplos de Integração

### Python (Boto3):

```python
import boto3
import json

sns = boto3.client('sns', endpoint_url='http://localhost:4566', region_name='us-east-1')

# Publicar notificação
response = sns.publish(
    TopicArn='arn:aws:sns:us-east-1:000000000000:PedidosConcluidos',
    Subject='Pedido Pronto!',
    Message=json.dumps({
        'pedidoId': 'pedido-123',
        'cliente': 'João Silva',
        'status': 'concluido'
    })
)

print(f"Message ID: {response['MessageId']}")
```

### Node.js (AWS SDK):

```javascript
const AWS = require('aws-sdk');

const sns = new AWS.SNS({
  endpoint: 'http://localhost:4566',
  region: 'us-east-1'
});

const params = {
  TopicArn: 'arn:aws:sns:us-east-1:000000000000:PedidosConcluidos',
  Subject: 'Pedido Pronto!',
  Message: JSON.stringify({
    pedidoId: 'pedido-123',
    cliente: 'João Silva',
    status: 'concluido'
  })
};

sns.publish(params, (err, data) => {
  if (err) console.error(err);
  else console.log('Message ID:', data.MessageId);
});
```

## 🔐 Segurança

- **Políticas de Acesso**: Controlar quem pode publicar/subscrever
- **Criptografia**: Usar KMS para criptografar mensagens (em produção)
- **HTTPS**: Sempre usar HTTPS para webhooks em produção
- **Confirmação**: Email/SMS requerem confirmação do destinatário

## 📈 Monitoramento

Métricas importantes:
- `NumberOfMessagesPublished`: Mensagens publicadas
- `NumberOfNotificationsDelivered`: Notificações entregues
- `NumberOfNotificationsFailed`: Notificações falhadas

## 🎯 Integração com Lambda

A Lambda de processamento deve publicar assim:

```python
import boto3
import json

def lambda_handler(event, context):
    sns = boto3.client('sns', endpoint_url='http://localhost:4566')
    
    # Processar pedido...
    pedido_id = event['pedidoId']
    
    # Publicar notificação
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:000000000000:PedidosConcluidos',
        Subject='Pedido Pronto!',
        Message=f'Pedido {pedido_id} concluído e comprovante disponível no S3',
        MessageAttributes={
            'pedidoId': {'DataType': 'String', 'StringValue': pedido_id},
            'tipo': {'DataType': 'String', 'StringValue': 'conclusao'}
        }
    )
    
    return {'statusCode': 200, 'body': 'Notificação enviada'}
```

## 🎯 Próximos Passos

1. ✅ Tópico SNS criado
2. ✅ Subscrições configuradas (email + HTTP)
3. ✅ Implementar Lambda para publicar notificações
4. ✅ Testar webhook HTTP
5. ✅ Adicionar mais subscrições conforme necessário
