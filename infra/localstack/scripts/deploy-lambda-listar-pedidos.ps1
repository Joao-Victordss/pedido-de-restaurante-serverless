#!/usr/bin/env pwsh
# Deploy Lambda Listar Pedidos

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🚀 Deploy Lambda Listar Pedidos" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "listar-pedidos"
$LAMBDA_DIR = Resolve-Path "src/lambdas/listar-pedidos"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"

# Criar função Lambda
Write-Host "📝 Criando Lambda..." -ForegroundColor Cyan

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

$result = aws --endpoint-url=$ENDPOINT `
    lambda create-function `
    --function-name $LAMBDA_NAME `
    --runtime python3.11 `
    --role arn:aws:iam::000000000000:role/lambda-role `
    --handler index.handler `
    --zip-file fileb://simple.zip `
    --region $REGION `
    --timeout 30 `
    --environment "Variables={AWS_ACCESS_KEY_ID=test,AWS_SECRET_ACCESS_KEY=test,AWS_DEFAULT_REGION=us-east-1,LOCALSTACK_HOSTNAME=host.docker.internal,DYNAMODB_TABLE=Pedidos}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao criar Lambda" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda criada: $LAMBDA_NAME" -ForegroundColor Green

# Limpar
Remove-Item "simple.zip" -ErrorAction SilentlyContinue
Set-Location "../../.."

Write-Host ""
Write-Host "🎉 Deploy completo!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Para testar a Lambda:" -ForegroundColor Cyan
Write-Host "   .\infra\localstack\scripts\test-lambda-listar-pedidos.ps1" -ForegroundColor Gray
