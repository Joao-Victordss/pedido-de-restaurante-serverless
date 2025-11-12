# SQS - Fila de Pedidos

Fila SQS para processamento assíncrono de pedidos do restaurante.

## 📋 Configuração da Fila

### Fila Principal: `pedidos-queue`

```yaml
Nome: pedidos-queue
Tipo: Standard Queue
Visibility Timeout: 30 segundos
Message Retention: 4 dias (345600 segundos)
Long Polling: 20 segundos
Dead Letter Queue: pedidos-queue-dlq (após 3 tentativas)
```

### Dead Letter Queue: `pedidos-queue-dlq`

Mensagens que falham no processamento após 3 tentativas são movidas para esta fila para análise.

## 📦 Formato das Mensagens

```json
{
  "pedidoId": "pedido-20251111120000",
  "acao": "processar_pedido",
  "dados": {
    "cliente": "Nome do Cliente",
    "mesa": 10,
    "itens": ["Item 1", "Item 2"],
    "total": 45.50
  },
  "timestamp": "2025-11-11T12:00:00Z"
}
```

## 🚀 Como Usar

### Criar a Fila

**PowerShell:**
```powershell
.\infra\sqs\create-queue-pedidos.ps1
```

**Bash:**
```bash
./infra/sqs/create-queue-pedidos.sh
```

### Testar a Fila

```powershell
.\infra\sqs\test-queue-pedidos.ps1
```

O script de teste executa:
1. ✅ Envio de mensagem de teste
2. ✅ Verificação dos atributos da fila
3. ✅ Recebimento de mensagem (long polling)
4. ✅ Deleção da mensagem após processamento
5. ✅ Verificação final da fila

## 🔄 Fluxo de Processamento

```
API Gateway → Lambda (Criar Pedido) → DynamoDB
                                    ↓
                                SQS Queue
                                    ↓
                      Lambda (Processar Pedido)
                                    ↓
                              S3 + SNS
```

### Características

- **Long Polling (20s)**: Reduz requisições desnecessárias e custos
- **Visibility Timeout (30s)**: Tempo que a mensagem fica invisível durante processamento
- **Message Retention (4 dias)**: Mensagens não processadas são mantidas por 4 dias
- **Dead Letter Queue**: Mensagens com falha após 3 tentativas vão para análise

## 📊 Monitoramento

### Atributos importantes:

- `ApproximateNumberOfMessages`: Mensagens disponíveis para processamento
- `ApproximateNumberOfMessagesNotVisible`: Mensagens em processamento
- `ApproximateNumberOfMessagesDelayed`: Mensagens com delay
- `ApproximateAgeOfOldestMessage`: Idade da mensagem mais antiga

### Verificar status:

```bash
aws sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/pedidos-queue \
  --attribute-names All \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

## 🔧 Comandos Úteis

### Enviar mensagem:

```bash
aws sqs send-message \
  --queue-url http://localhost:4566/000000000000/pedidos-queue \
  --message-body '{"pedidoId":"123","acao":"processar"}' \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Receber mensagem:

```bash
aws sqs receive-message \
  --queue-url http://localhost:4566/000000000000/pedidos-queue \
  --max-number-of-messages 1 \
  --wait-time-seconds 20 \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Purgar fila (limpar todas as mensagens):

```bash
aws sqs purge-queue \
  --queue-url http://localhost:4566/000000000000/pedidos-queue \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

## 🎯 Próximos Passos

1. ✅ Criar Lambda para enviar mensagens à fila
2. ✅ Criar Lambda para processar mensagens da fila
3. ✅ Configurar trigger SQS → Lambda
4. ✅ Implementar tratamento de erros e retry
5. ✅ Adicionar métricas e alarmes
