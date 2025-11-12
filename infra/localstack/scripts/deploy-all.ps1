#!/usr/bin/env pwsh
# Deploy completo - Infraestrutura + Lambdas + API Gateway

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploy Completo - Pedidos Serverless" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

# Verificar se LocalStack está rodando
Write-Host "🔍 Verificando LocalStack..." -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ LocalStack está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack não está rodando!" -ForegroundColor Red
    Write-Host "Execute: make up" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Passo 1: Deploy da infraestrutura AWS
Write-Host "📦 Passo 1/4: Deploy da infraestrutura AWS" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Gray

$infraScript = Join-Path $PROJECT_ROOT "infra\aws\deploy-all.ps1"
if (Test-Path $infraScript) {
    & $infraScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro no deploy da infraestrutura" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  Script de infraestrutura não encontrado, pulando..." -ForegroundColor Yellow
    Write-Host "    Certifique-se de que os recursos AWS já estão provisionados" -ForegroundColor Gray
}

Write-Host ""

# Passo 2: Deploy das Lambdas
Write-Host "⚡ Passo 2/4: Deploy das Lambda Functions" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Gray

Write-Host "`n🔸 Lambda criar-pedido..." -ForegroundColor Yellow
& "$SCRIPT_DIR\deploy-lambda-criar-pedido.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no deploy da Lambda criar-pedido" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔸 Lambda processar-pedido..." -ForegroundColor Yellow
& "$SCRIPT_DIR\deploy-lambda-processar-pedido.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no deploy da Lambda processar-pedido" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔸 Lambda listar-pedidos..." -ForegroundColor Yellow
& "$SCRIPT_DIR\deploy-lambda-listar-pedidos.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no deploy da Lambda listar-pedidos" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Passo 3: Deploy do API Gateway
Write-Host "🌐 Passo 3/4: Deploy do API Gateway" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Gray

& "$SCRIPT_DIR\deploy-apigateway.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no deploy do API Gateway" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Passo 4: Verificar deploy
Write-Host "✅ Passo 4/4: Verificação Final" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Gray

# Ler API ID do arquivo (está na raiz do projeto)
$apiIdFile = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR))) "api-id.txt"
if (Test-Path $apiIdFile) {
    $API_ID = Get-Content $apiIdFile -Raw | ForEach-Object { $_.Trim() }
} else {
    Write-Host "⚠️  Arquivo api-id.txt não encontrado" -ForegroundColor Yellow
    $API_ID = "unknown"
}

# Verificar recursos AWS
Write-Host "`n📊 Recursos provisionados:" -ForegroundColor Cyan

# DynamoDB
$tables = aws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1 --query 'TableNames' --output text
Write-Host "  ✓ DynamoDB: $tables" -ForegroundColor Green

# SQS
$queues = aws --endpoint-url=http://localhost:4566 sqs list-queues --region us-east-1 --query 'QueueUrls' --output text
Write-Host "  ✓ SQS: $(($queues -split "`n").Count) filas" -ForegroundColor Green

# S3
$buckets = aws --endpoint-url=http://localhost:4566 s3 ls | Measure-Object -Line
Write-Host "  ✓ S3: $($buckets.Lines) buckets" -ForegroundColor Green

# SNS
$topics = aws --endpoint-url=http://localhost:4566 sns list-topics --region us-east-1 --query 'Topics' --output text
Write-Host "  ✓ SNS: $(($topics -split "`n").Count) tópicos" -ForegroundColor Green

# Lambda
$functions = aws --endpoint-url=http://localhost:4566 lambda list-functions --region us-east-1 --query 'Functions[].FunctionName' --output text
Write-Host "  ✓ Lambda: $functions" -ForegroundColor Green

# API Gateway
Write-Host "  ✓ API Gateway: $API_ID" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "🎉 Deploy completo com sucesso!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Informações da API
Write-Host "🌐 API Gateway Endpoints:" -ForegroundColor Cyan
Write-Host "   Base URL: http://localhost:4566/restapis/$API_ID/prod/_user_request_" -ForegroundColor White
Write-Host ""
Write-Host "   POST   /pedidos          - Criar pedido" -ForegroundColor Yellow
Write-Host "   GET    /pedidos          - Listar pedidos" -ForegroundColor Yellow
Write-Host "   GET    /pedidos/{id}     - Buscar pedido" -ForegroundColor Yellow
Write-Host ""

# Comandos úteis
Write-Host "💡 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   # Testar API Gateway" -ForegroundColor Gray
Write-Host "   .\infra\localstack\scripts\test-apigateway.ps1" -ForegroundColor White
Write-Host ""
Write-Host "   # Ver logs de uma Lambda" -ForegroundColor Gray
Write-Host "   aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/criar-pedido --region us-east-1 --follow" -ForegroundColor White
Write-Host ""
Write-Host "   # Exemplo com curl" -ForegroundColor Gray
Write-Host "   curl -X POST http://localhost:4566/restapis/$API_ID/prod/_user_request_/pedidos \" -ForegroundColor White
Write-Host "     -H 'Content-Type: application/json' \" -ForegroundColor White
Write-Host "     -d '{\"cliente\":\"João Silva\",\"mesa\":10,\"itens\":[\"Pizza\",\"Refrigerante\"]}'" -ForegroundColor White
Write-Host ""

# Documentação
Write-Host "📚 Documentação:" -ForegroundColor Cyan
Write-Host "   API: src\api\README.md" -ForegroundColor White
Write-Host ""
