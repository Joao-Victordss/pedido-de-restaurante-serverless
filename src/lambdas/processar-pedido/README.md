# Lambda Processar Pedido

Lambda function que processa pedidos consumindo mensagens da fila SQS.

## Funcionalidades

1. **Consumir SQS**: Recebe mensagens da fila `pedidos-queue`
2. **Gerar PDF**: Cria comprovante do pedido (simulado)
3. **Upload S3**: Salva PDF no bucket `pedidos-comprovantes`
4. **Atualizar DynamoDB**: Muda status do pedido para `processado`
5. **Notificar SNS**: Publica mensagem no tópico `PedidosConcluidos`

## Trigger

- **Tipo**: SQS Queue
- **Fila**: `pedidos-queue`
- **Batch Size**: 10 mensagens
- **Batch Window**: 0 segundos

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `LOCALSTACK_HOSTNAME` | Hostname do LocalStack | `localhost` |
| `AWS_ENDPOINT_URL` | Endpoint dos serviços AWS | `http://localhost:4566` |
| `DYNAMODB_TABLE` | Nome da tabela DynamoDB | `Pedidos` |
| `S3_BUCKET` | Nome do bucket S3 | `pedidos-comprovantes` |
| `SNS_TOPIC_ARN` | ARN do tópico SNS | `arn:aws:sns:us-east-1:000000000000:PedidosConcluidos` |

## Formato da Mensagem SQS (Input)

```json
{
  "pedidoId": "pedido-20241112010203",
  "cliente": "João Silva",
  "itens": ["Pizza", "Refrigerante"],
  "mesa": 5,
  "timestamp": "2024-11-12T01:02:03.456789"
}
```

## Formato do PDF Gerado

O PDF é gerado em formato texto simulado contendo:
- Cabeçalho com título
- ID do pedido
- Nome do cliente
- Número da mesa
- Data/hora
- Lista de itens
- Rodapé com status

Em produção, seria um PDF real usando bibliotecas como:
- `reportlab`
- `WeasyPrint`
- `pdfkit`

## Estrutura S3

PDFs são salvos em:
```
s3://pedidos-comprovantes/comprovantes/{pedidoId}.pdf
```

Exemplo:
```
s3://pedidos-comprovantes/comprovantes/pedido-20241112010203.pdf
```

## Atualização DynamoDB

A Lambda atualiza os seguintes campos:
- `status`: `"processado"`
- `updated_at`: timestamp ISO 8601
- `comprovante_url`: chave S3 do PDF

## Notificação SNS

Mensagem publicada:
```json
{
  "pedidoId": "pedido-20241112010203",
  "cliente": "João Silva",
  "mesa": 5,
  "status": "processado",
  "comprovante": "comprovantes/pedido-20241112010203.pdf",
  "timestamp": "2024-11-12T01:02:05.123456"
}
```

## Tratamento de Erros

- **Erro de processamento**: Pedido marcado como `erro` no DynamoDB
- **Falha parcial**: Usa `batchItemFailures` para reprocessamento seletivo
- **Logs**: Todos os passos são logados no CloudWatch

## Fluxo de Execução

```
1. SQS Trigger → Lambda recebe batch de mensagens
2. Para cada mensagem:
   a. Parse do JSON
   b. Gerar PDF
   c. Upload para S3
   d. Update DynamoDB
   e. Publish SNS
3. Retorna lista de falhas (se houver)
```

## Testes Locais (LocalStack)

### Deploy
```powershell
.\infra\localstack\scripts\deploy-lambda-processar-pedido.ps1
```

### Enviar mensagem de teste para SQS
```powershell
aws --endpoint-url=http://localhost:4566 sqs send-message `
  --queue-url http://localhost:4566/000000000000/pedidos-queue `
  --message-body '{\"pedidoId\":\"pedido-test-001\",\"cliente\":\"Maria Santos\",\"itens\":[\"Hamburguer\",\"Batata Frita\"],\"mesa\":10,\"timestamp\":\"2024-11-12T01:00:00.000Z\"}'
```

### Verificar PDF no S3
```powershell
aws --endpoint-url=http://localhost:4566 s3 ls s3://pedidos-comprovantes/comprovantes/
```

### Baixar PDF
```powershell
aws --endpoint-url=http://localhost:4566 s3 cp s3://pedidos-comprovantes/comprovantes/pedido-test-001.pdf ./pedido-test-001.pdf
```

### Verificar status no DynamoDB
```powershell
aws --endpoint-url=http://localhost:4566 dynamodb get-item `
  --table-name Pedidos `
  --key '{\"id\":{\"S\":\"pedido-test-001\"}}'
```

### Verificar mensagem no SNS
```powershell
# Verificar se mensagem foi publicada (logs da Lambda)
aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/processar-pedido --follow
```

## Logs

A Lambda faz log de:
- Evento recebido
- Cada mensagem processada
- Etapas do processamento (PDF, S3, DynamoDB, SNS)
- Erros e exceções
- Resultado final (sucessos e falhas)

## Permissões Necessárias

- `dynamodb:UpdateItem` - Atualizar status do pedido
- `s3:PutObject` - Upload do PDF
- `sns:Publish` - Enviar notificação
- `sqs:ReceiveMessage` - Receber mensagens
- `sqs:DeleteMessage` - Remover mensagens processadas
- `sqs:GetQueueAttributes` - Ler atributos da fila

## Métricas

- Mensagens processadas com sucesso
- Mensagens com falha
- Tempo de processamento
- Tamanho dos PDFs gerados
- Taxa de erro

## Próximos Passos

1. Implementar geração de PDF real com `reportlab`
2. Adicionar template HTML para PDF
3. Incluir logo e formatação profissional
4. Adicionar validação de campos obrigatórios
5. Implementar retry exponencial
6. Adicionar circuit breaker
