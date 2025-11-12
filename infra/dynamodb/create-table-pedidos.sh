#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
TABLE_NAME="Pedidos"

echo "Criando tabela DynamoDB: $TABLE_NAME"

aws dynamodb create-table \
  --endpoint-url "$ENDPOINT" \
  --region "$REGION" \
  --table-name "$TABLE_NAME" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Project,Value=RestaurantePedidos

echo "Aguardando tabela ficar ativa..."
aws dynamodb wait table-exists \
  --endpoint-url "$ENDPOINT" \
  --region "$REGION" \
  --table-name "$TABLE_NAME"

echo "✅ Tabela $TABLE_NAME criada com sucesso!"

# Verificar a tabela
echo "Detalhes da tabela:"
aws dynamodb describe-table \
  --endpoint-url "$ENDPOINT" \
  --region "$REGION" \
  --table-name "$TABLE_NAME" \
  --query 'Table.[TableName,TableStatus,KeySchema,AttributeDefinitions]' \
  --output json
