#!/bin/bash
# Script para criar bucket S3 para comprovantes de pedidos no LocalStack

set -e

ENDPOINT="http://localhost:4566"
REGION="us-east-1"
BUCKET_NAME="pedidos-comprovantes"

echo "=== Criando Bucket S3: $BUCKET_NAME ==="

# Criar o bucket S3
echo -e "\nCriando bucket..."

aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION"

echo "✅ Bucket criado com sucesso!"

# Verificar se o bucket foi criado
echo -e "\nVerificando bucket..."

BUCKET_EXISTS=$(aws s3api list-buckets \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION" \
    --output json | jq -r ".Buckets[] | select(.Name==\"$BUCKET_NAME\") | .Name")

if [ "$BUCKET_EXISTS" == "$BUCKET_NAME" ]; then
    echo "✅ Bucket encontrado na lista!"
    CREATED_DATE=$(aws s3api list-buckets \
        --endpoint-url "$ENDPOINT" \
        --region "$REGION" \
        --output json | jq -r ".Buckets[] | select(.Name==\"$BUCKET_NAME\") | .CreationDate")
    echo "   Nome: $BUCKET_NAME"
    echo "   Criado em: $CREATED_DATE"
else
    echo "❌ Bucket não encontrado!"
    exit 1
fi

# Configurar versionamento
echo -e "\nConfigurando versionamento..."

aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION"

echo "✅ Versionamento habilitado!"

# Configurar ciclo de vida
echo -e "\nConfigurando ciclo de vida..."

LIFECYCLE_POLICY='{
  "Rules": [
    {
      "ID": "DeleteOldComprovantes",
      "Status": "Enabled",
      "Expiration": {
        "Days": 90
      },
      "Filter": {
        "Prefix": ""
      }
    }
  ]
}'

echo "$LIFECYCLE_POLICY" > /tmp/lifecycle-policy.json

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration file:///tmp/lifecycle-policy.json \
    --endpoint-url "$ENDPOINT" \
    --region "$REGION"

rm /tmp/lifecycle-policy.json

echo "✅ Ciclo de vida configurado! (Arquivos expiram após 90 dias)"

# Resumo
echo -e "\n✅ Configuração completa!"
echo -e "\nResumo:"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Bucket URL: http://$BUCKET_NAME.s3.localhost.localstack.cloud:4566"
echo "  Endpoint: $ENDPOINT"
echo "  Region: $REGION"
echo "  Versionamento: Habilitado"
echo "  Retenção: 90 dias"
