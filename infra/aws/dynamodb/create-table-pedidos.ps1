# Script PowerShell para criar tabela DynamoDB no LocalStack
$ErrorActionPreference = "Stop"

$REGION = if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" }
$ENDPOINT = if ($env:LOCALSTACK_ENDPOINT) { $env:LOCALSTACK_ENDPOINT } else { "http://localhost:4566" }
$TABLE_NAME = "Pedidos"

Write-Host "Criando tabela DynamoDB: $TABLE_NAME" -ForegroundColor Cyan

# Criar a tabela
aws dynamodb create-table `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME `
  --attribute-definitions AttributeName=id,AttributeType=S `
  --key-schema AttributeName=id,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --tags Key=Project,Value=RestaurantePedidos

Write-Host "Aguardando tabela ficar ativa..." -ForegroundColor Yellow
aws dynamodb wait table-exists `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME

Write-Host "✅ Tabela $TABLE_NAME criada com sucesso!" -ForegroundColor Green

# Verificar a tabela
Write-Host "`nDetalhes da tabela:" -ForegroundColor Cyan
aws dynamodb describe-table `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME `
  --query 'Table.[TableName,TableStatus,KeySchema,AttributeDefinitions]' `
  --output json
