#!/bin/bash
# Script para criar tópico SNS para notificações de pedidos no LocalStack

set -e

ENDPOINT="http://localhost:4566"
REGION="us-east-1"
TOPIC_NAME="PedidosConcluidos"

echo "=== Criando Tópico SNS: $TOPIC_NAME ==="

# Criar o tópico SNS
echo -e "\nCriando tópico..."

TOPIC_ARN=$(aws sns create-topic \
    --name "$TOPIC_NAME" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.TopicArn')

echo "✅ Tópico criado com sucesso!"
echo "   ARN: $TOPIC_ARN"

# Configurar atributos do tópico
echo -e "\nConfigurando atributos do tópico..."

aws sns set-topic-attributes \
    --topic-arn "$TOPIC_ARN" \
    --attribute-name DisplayName \
    --attribute-value "Notificacoes de Pedidos Concluidos" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION"

echo "✅ Display Name configurado!"

# Obter atributos do tópico
echo -e "\nObtendo atributos do tópico..."

ATTRIBUTES=$(aws sns get-topic-attributes \
    --topic-arn "$TOPIC_ARN" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json)

DISPLAY_NAME=$(echo "$ATTRIBUTES" | jq -r '.Attributes.DisplayName')
OWNER=$(echo "$ATTRIBUTES" | jq -r '.Attributes.Owner')

echo "✅ Atributos do tópico:"
echo "   Topic ARN: $TOPIC_ARN"
echo "   Display Name: $DISPLAY_NAME"
echo "   Owner: $OWNER"

# Criar subscrição de teste via email
echo -e "\nCriando subscrição de teste (email)..."

EMAIL_SUB_ARN=$(aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "cozinha@restaurante.com" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.SubscriptionArn')

echo "✅ Subscrição criada!"
echo "   Subscription ARN: $EMAIL_SUB_ARN"
echo "   Endpoint: cozinha@restaurante.com"
echo "   Protocol: email"

# Criar subscrição HTTP para webhook
echo -e "\nCriando subscrição HTTP..."

HTTP_SUB_ARN=$(aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol http \
    --notification-endpoint "http://localhost:3000/webhook/pedidos" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r '.SubscriptionArn')

echo "✅ Subscrição HTTP criada!"
echo "   Subscription ARN: $HTTP_SUB_ARN"
echo "   Endpoint: http://localhost:3000/webhook/pedidos"

# Listar todas as subscrições
echo -e "\nListando subscrições..."

SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic \
    --topic-arn "$TOPIC_ARN" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq '.Subscriptions | length')

echo "✅ Total de subscrições: $SUBSCRIPTIONS"

echo -e "\n✅ Configuração completa!"
echo -e "\nResumo:"
echo "  Topic Name: $TOPIC_NAME"
echo "  Topic ARN: $TOPIC_ARN"
echo "  Subscrições:"
echo "    - Email: cozinha@restaurante.com"
echo "    - HTTP: http://localhost:3000/webhook/pedidos"
