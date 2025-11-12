#!/bin/bash
# Script para provisionar todos os recursos AWS no LocalStack
# Executa os scripts de criação de cada serviço em ordem

set -e

echo "🚀 Iniciando deploy de todos os recursos AWS..."
echo ""

# Diretório base
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
AWS_DIR="$BASE_DIR/aws"

# Verificar se LocalStack está rodando
echo "🔍 Verificando LocalStack..."
if aws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1 > /dev/null 2>&1; then
    echo "✅ LocalStack está rodando"
else
    echo "❌ LocalStack não está rodando!"
    echo "Execute: make up"
    exit 1
fi
echo ""

# 1. DynamoDB - Tabela Pedidos
echo "📊 [1/4] Criando tabela DynamoDB Pedidos..."
DYNAMO_SCRIPT="$AWS_DIR/dynamodb/create-table-pedidos.sh"
if [ -f "$DYNAMO_SCRIPT" ]; then
    bash "$DYNAMO_SCRIPT"
    echo "✅ Tabela DynamoDB criada com sucesso"
else
    echo "⚠️ Script não encontrado: $DYNAMO_SCRIPT"
fi
echo ""

# 2. SQS - Fila de Pedidos
echo "📬 [2/4] Criando fila SQS pedidos-queue..."
SQS_SCRIPT="$AWS_DIR/sqs/create-queue-pedidos.sh"
if [ -f "$SQS_SCRIPT" ]; then
    bash "$SQS_SCRIPT"
    echo "✅ Fila SQS criada com sucesso"
else
    echo "⚠️ Script não encontrado: $SQS_SCRIPT"
fi
echo ""

# 3. S3 - Bucket de Comprovantes
echo "🪣 [3/4] Criando bucket S3 pedidos-comprovantes..."
S3_SCRIPT="$AWS_DIR/s3/create-bucket-comprovantes.sh"
if [ -f "$S3_SCRIPT" ]; then
    bash "$S3_SCRIPT"
    echo "✅ Bucket S3 criado com sucesso"
else
    echo "⚠️ Script não encontrado: $S3_SCRIPT"
fi
echo ""

# 4. SNS - Tópico de Pedidos Concluídos
echo "📢 [4/4] Criando tópico SNS PedidosConcluidos..."
SNS_SCRIPT="$AWS_DIR/sns/create-topic-pedidos.sh"
if [ -f "$SNS_SCRIPT" ]; then
    bash "$SNS_SCRIPT"
    echo "✅ Tópico SNS criado com sucesso"
else
    echo "⚠️ Script não encontrado: $SNS_SCRIPT"
fi
echo ""

# Resumo
echo "============================================================"
echo "🎉 Deploy completo!"
echo "============================================================"
echo ""
echo "Recursos provisionados:"
echo "  📊 DynamoDB: Pedidos"
echo "  📬 SQS: pedidos-queue (com DLQ)"
echo "  🪣 S3: pedidos-comprovantes"
echo "  📢 SNS: PedidosConcluidos"
echo ""
echo "Próximos passos:"
echo "  1. Testar recursos: ./infra/aws/{serviço}/test-*.sh"
echo "  2. Implementar Lambdas: ./src/lambdas/"
echo "  3. Configurar API Gateway"
echo ""
echo "Documentação completa: ./docs/setup.md"
