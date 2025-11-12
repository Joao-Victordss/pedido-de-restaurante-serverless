#!/bin/bash
# Script para criar a fila SQS de Pedidos no LocalStack

set -e

ENDPOINT="http://localhost:4566"
REGION="us-east-1"
QUEUE_NAME="pedidos-queue"

echo "=== Criando Fila SQS: $QUEUE_NAME ==="

# Criar a fila SQS
echo -e "\nCriando fila..."

QUEUE_URL=$(aws sqs create-queue \
    --queue-name "$QUEUE_NAME" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --attributes '{"VisibilityTimeout":"30","MessageRetentionPeriod":"345600","ReceiveMessageWaitTimeSeconds":"20"}' \
    --output json | jq -r '.QueueUrl')

echo "✅ Fila criada com sucesso!"
echo "   URL: $QUEUE_URL"

# Obter ARN da fila
echo -e "\nObtendo atributos da fila..."

QUEUE_ARN=$(aws sqs get-queue-attributes \
    --queue-url "$QUEUE_URL" \
    --attribute-names QueueArn \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.Attributes.QueueArn')

echo "✅ ARN: $QUEUE_ARN"

# Criar Dead Letter Queue (DLQ)
echo -e "\nCriando Dead Letter Queue..."

DLQ_URL=$(aws sqs create-queue \
    --queue-name "${QUEUE_NAME}-dlq" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.QueueUrl')

DLQ_ARN=$(aws sqs get-queue-attributes \
    --queue-url "$DLQ_URL" \
    --attribute-names QueueArn \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.Attributes.QueueArn')

echo "✅ DLQ criada!"
echo "   DLQ URL: $DLQ_URL"
echo "   DLQ ARN: $DLQ_ARN"

# Configurar atributos da fila principal com DLQ
echo -e "\nConfigurando atributos da fila principal..."

REDRIVE_POLICY="{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"3\"}"

aws sqs set-queue-attributes \
    --queue-url "$QUEUE_URL" \
    --attributes VisibilityTimeout=30,MessageRetentionPeriod=345600,ReceiveMessageWaitTimeSeconds=20,RedrivePolicy="$REDRIVE_POLICY" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION"

echo "✅ Atributos configurados!"

echo -e "\n✅ Configuração completa!"
echo -e "\nResumo:"
echo "  Queue Name: $QUEUE_NAME"
echo "  Queue URL: $QUEUE_URL"
echo "  Queue ARN: $QUEUE_ARN"
echo "  DLQ Name: ${QUEUE_NAME}-dlq"
echo "  DLQ URL: $DLQ_URL"
echo "  DLQ ARN: $DLQ_ARN"
echo "  Max Receive Count: 3"
echo "  Visibility Timeout: 30s"
echo "  Message Retention: 4 dias"
echo "  Long Polling: 20s"
