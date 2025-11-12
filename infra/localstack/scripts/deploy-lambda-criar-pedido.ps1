#!/usr/bin/env pwsh
# Deploy Lambda usando hot-reload do LocalStack (sem ZIP)

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🚀 Deploy Lambda Criar Pedido (Hot Reload)" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "criar-pedido"
$LAMBDA_DIR = Resolve-Path "src/lambdas/criar-pedido"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"

# 1. Criar função Lambda apontando diretamente para o código local
Write-Host "📝 Criando Lambda com código local..." -ForegroundColor Cyan

# Criar arquivo ZIP mínimo apenas com o index.py
Set-Location $LAMBDA_DIR
if (Test-Path "simple.zip") { Remove-Item "simple.zip" }
Compress-Archive -Path "index.py" -DestinationPath "simple.zip" -Force

# Verificar se Lambda existe
$lambdaExists = $false
$ErrorActionPreference = "SilentlyContinue"
aws --endpoint-url=$ENDPOINT lambda get-function --function-name $LAMBDA_NAME --region $REGION 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $lambdaExists = $true }
$ErrorActionPreference = "Stop"

if ($lambdaExists) {
    Write-Host "Deletando Lambda existente..." -ForegroundColor Gray
    aws --endpoint-url=$ENDPOINT lambda delete-function --function-name $LAMBDA_NAME --region $REGION | Out-Null
}

Write-Host "Criando nova Lambda..." -ForegroundColor Gray

# Usar variáveis de ambiente que apontam para host.docker.internal
# Importante: LocalStack precisa conseguir acessar localhost do host
$result = aws --endpoint-url=$ENDPOINT `
    lambda create-function `
    --function-name $LAMBDA_NAME `
    --runtime python3.11 `
    --role arn:aws:iam::000000000000:role/lambda-role `
    --handler index.handler `
    --zip-file fileb://simple.zip `
    --region $REGION `
    --timeout 30 `
    --environment "Variables={AWS_ACCESS_KEY_ID=test,AWS_SECRET_ACCESS_KEY=test,AWS_DEFAULT_REGION=us-east-1,LOCALSTACK_HOSTNAME=host.docker.internal,DYNAMODB_TABLE=Pedidos,SQS_QUEUE_URL=http://host.docker.internal:4566/000000000000/pedidos-queue}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao criar Lambda" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda criada: $LAMBDA_NAME" -ForegroundColor Green
Write-Host ""

# Limpar
Remove-Item "simple.zip" -ErrorAction SilentlyContinue

Set-Location "../../.."

Write-Host ""
Write-Host "🎉 Deploy completo!" -ForegroundColor Green
Write-Host ""
Write-Host "� Para testar a Lambda:" -ForegroundColor Cyan
Write-Host "   .\infra\localstack\scripts\test-lambda-criar-pedido.ps1" -ForegroundColor Gray
