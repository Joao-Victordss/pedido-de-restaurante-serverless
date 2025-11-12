#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:${EDGE_PORT:-4566}}"

awsls() {
  aws --endpoint-url "$ENDPOINT" --region "$REGION" "$@"
}

echo "Healthcheck do LocalStack..."
HEALTH_BODY=$(curl -sS "$ENDPOINT/health" || true)
# Tenta parsear com jq; se falhar mostra o body cru para diagnóstico
if printf '%s' "$HEALTH_BODY" | jq . >/dev/null 2>&1; then
  printf '%s
' "$HEALTH_BODY" | jq .
else
  printf 'Health endpoint returned (non-JSON or parse failed):\n%s\n' "$HEALTH_BODY"
fi

echo "Checando AWS CLI..."
aws --version

echo "Listando serviços básicos..."
awsls s3 ls || true
awsls sqs list-queues || true
awsls dynamodb list-tables || true
awsls sns list-topics || true

# Recursos de validação do ambiente
BUCKET="health-check-bucket"
QUEUE="health-check-queue"
TABLE="HealthCheckTable"
TOPIC_NAME="health-check-topic"

echo "Criando bucket S3 se não existir: s3://$BUCKET"
if ! awsls s3 ls "s3://$BUCKET" 2>/dev/null; then
  awsls s3 mb "s3://$BUCKET" || true
fi

echo "Criando fila SQS se não existir: $QUEUE"
QUEUE_URL=$(awsls sqs create-queue --queue-name "$QUEUE" --query 'QueueUrl' --output text)

if [ -z "${QUEUE_URL:-}" ]; then
  # tentar recuperar URL se criação não retornou por algum motivo
  QUEUE_URL=$(awsls sqs get-queue-url --queue-name "$QUEUE" --query 'QueueUrl' --output text 2>/dev/null || true)
fi

echo "Criando tabela DynamoDB se não existir: $TABLE"
if ! awsls dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  awsls dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  echo "Aguardando tabela ficar ativa..."
  awsls dynamodb wait table-exists --table-name "$TABLE"
fi

echo "Criando tópico SNS se não existir: $TOPIC_NAME"
TOPIC_ARN=$(awsls sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)

# Exercitar os recursos
echo "Enviando arquivo de teste ao S3..."
echo "ok" | awsls s3 cp - "s3://$BUCKET/ping.txt" || true

echo "Enviando mensagem de teste ao SQS..."
if [ -n "${QUEUE_URL:-}" ]; then
  awsls sqs send-message --queue-url "$QUEUE_URL" --message-body "ping" || true
else
  echo "Aviso: QUEUE_URL vazio, pulando envio para SQS"
fi

echo "Publicando mensagem de teste no SNS..."
if [ -n "${TOPIC_ARN:-}" ]; then
  awsls sns publish --topic-arn "$TOPIC_ARN" --message "ping" || true
else
  echo "Aviso: TOPIC_ARN vazio, pulando publish SNS"
fi

echo "Bootstrap finalizado com sucesso."
echo "Resumo:"
echo " - S3 bucket: s3://$BUCKET"
echo " - SQS queue:  $QUEUE_URL"
echo " - DynamoDB:   $TABLE"
echo " - SNS topic:  $TOPIC_ARN"
