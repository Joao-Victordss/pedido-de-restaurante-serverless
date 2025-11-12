# Script para criar a fila SQS de Pedidos no LocalStack
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$QUEUE_NAME = "pedidos-queue"

Write-Host "=== Criando Fila SQS: $QUEUE_NAME ===" -ForegroundColor Cyan

# Criar a fila SQS principal
Write-Host "`nCriando fila..." -ForegroundColor Yellow

$result = aws sqs create-queue `
    --queue-name $QUEUE_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$queueUrl = $result.QueueUrl
Write-Host "✅ Fila criada com sucesso!" -ForegroundColor Green
Write-Host "   URL: $queueUrl" -ForegroundColor Gray

# Obter ARN da fila
Write-Host "`nObtendo atributos da fila..." -ForegroundColor Yellow

$attributes = aws sqs get-queue-attributes `
    --queue-url $queueUrl `
    --attribute-names All `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$queueArn = $attributes.Attributes.QueueArn
Write-Host "✅ ARN: $queueArn" -ForegroundColor Green

# Criar Dead Letter Queue (DLQ)
Write-Host "`nCriando Dead Letter Queue..." -ForegroundColor Yellow

$dlqResult = aws sqs create-queue `
    --queue-name "$QUEUE_NAME-dlq" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$dlqUrl = $dlqResult.QueueUrl

$dlqAttributes = aws sqs get-queue-attributes `
    --queue-url $dlqUrl `
    --attribute-names QueueArn `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$dlqArn = $dlqAttributes.Attributes.QueueArn
Write-Host "✅ DLQ criada!" -ForegroundColor Green
Write-Host "   DLQ URL: $dlqUrl" -ForegroundColor Gray
Write-Host "   DLQ ARN: $dlqArn" -ForegroundColor Gray

# Configurar atributos da fila principal com DLQ
Write-Host "`nConfigurando atributos da fila principal..." -ForegroundColor Yellow

# Configurar atributos básicos primeiro
aws sqs set-queue-attributes `
    --queue-url $queueUrl `
    --attributes VisibilityTimeout=30,MessageRetentionPeriod=345600,ReceiveMessageWaitTimeSeconds=20 `
    --endpoint-url $ENDPOINT `
    --region $REGION

# Configurar RedrivePolicy - o JSON precisa ser duplamente escapado
# O valor de RedrivePolicy é um JSON string, então as aspas internas precisam de \\\"
$redrivePolicyEscaped = '{\\\"deadLetterTargetArn\\\":\\\"' + $dlqArn + '\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}'

aws sqs set-queue-attributes `
    --queue-url $queueUrl `
    --attributes ('{\"RedrivePolicy\":\"' + $redrivePolicyEscaped + '\"}') `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Atributos e DLQ configurados!" -ForegroundColor Green

Write-Host "`n✅ Configuração completa!" -ForegroundColor Green
Write-Host "`nResumo:" -ForegroundColor Cyan
Write-Host "  Queue Name: $QUEUE_NAME" -ForegroundColor White
Write-Host "  Queue URL: $queueUrl" -ForegroundColor White
Write-Host "  Queue ARN: $queueArn" -ForegroundColor White
Write-Host "  DLQ Name: $QUEUE_NAME-dlq" -ForegroundColor White
Write-Host "  DLQ URL: $dlqUrl" -ForegroundColor White
Write-Host "  DLQ ARN: $dlqArn" -ForegroundColor White
Write-Host "  Max Receive Count: 3" -ForegroundColor White
Write-Host "  Visibility Timeout: 30s" -ForegroundColor White
Write-Host "  Message Retention: 4 dias" -ForegroundColor White
Write-Host "  Long Polling: 20s" -ForegroundColor White
