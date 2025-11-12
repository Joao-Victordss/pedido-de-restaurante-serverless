#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:${EDGE_PORT:-4566}}"

awsls() {
  aws --endpoint-url "$ENDPOINT" --region "$REGION" "$@"
}

BUCKET="health-check-bucket"
QUEUE_NAME="health-check-queue"
TABLE="HealthCheckTable"
TOPIC_NAME="health-check-topic"

echo "Tentando remover objetos do bucket S3: $BUCKET"
if awsls s3 ls "s3://$BUCKET" >/dev/null 2>&1; then
  awsls s3 rm "s3://$BUCKET" --recursive || true
  awsls s3 rb "s3://$BUCKET" || true
fi

echo "Removendo fila SQS: $QUEUE_NAME"
QUEUE_URL=$(awsls sqs get-queue-url --queue-name "$QUEUE_NAME" --query 'QueueUrl' --output text 2>/dev/null || true)
if [ -n "${QUEUE_URL:-}" ]; then
  awsls sqs purge-queue --queue-url "$QUEUE_URL" || true
  awsls sqs delete-queue --queue-url "$QUEUE_URL" || true
fi

echo "Removendo tabela DynamoDB: $TABLE"
if awsls dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  awsls dynamodb delete-table --table-name "$TABLE" || true
  awsls dynamodb wait table-not-exists --table-name "$TABLE" || true
fi

echo "Removendo tópico SNS: $TOPIC_NAME"
TOPIC_ARN=$(awsls sns list-topics --query "Topics[?ends_with(TopicArn, ':${TOPIC_NAME}')].TopicArn" --output text)
if [ -n "${TOPIC_ARN:-}" ]; then
  awsls sns delete-topic --topic-arn "$TOPIC_ARN" || true
fi

echo "Teardown concluído."
