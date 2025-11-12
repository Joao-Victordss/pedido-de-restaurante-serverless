#!/usr/bin/env pwsh
# Script para iniciar o frontend com proxy

$ErrorActionPreference = "Stop"

Write-Host "🎨 Iniciando Frontend com Proxy" -ForegroundColor Cyan
Write-Host ""

# Verificar se LocalStack está rodando
Write-Host "🔍 Verificando LocalStack..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ LocalStack está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack não está rodando!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Inicie o LocalStack primeiro:" -ForegroundColor Yellow
    Write-Host "   make up" -ForegroundColor Gray
    Write-Host "   # ou" -ForegroundColor Gray
    Write-Host "   docker-compose -f infra/docker-compose.yml up -d" -ForegroundColor Gray
    exit 1
}

# Verificar se API Gateway está deployado
Write-Host "🔍 Verificando API Gateway..." -ForegroundColor Cyan
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

$apiId = aws --endpoint-url=http://localhost:4566 `
    apigateway get-rest-apis `
    --region us-east-1 `
    --query "items[?name=='pedidos-api'].id" `
    --output text

if (-not $apiId) {
    Write-Host "⚠️  API Gateway não encontrado" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Fazendo deploy do API Gateway..." -ForegroundColor Cyan
    .\infra\localstack\scripts\deploy-apigateway.ps1
    
    # Buscar API ID novamente
    $apiId = aws --endpoint-url=http://localhost:4566 `
        apigateway get-rest-apis `
        --region us-east-1 `
        --query "items[?name=='pedidos-api'].id" `
        --output text
}

Write-Host "✅ API Gateway encontrado: $apiId" -ForegroundColor Green

# Verificar Python
Write-Host ""
Write-Host "🔍 Verificando Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python não encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instale Python 3 para usar o proxy:" -ForegroundColor Yellow
    Write-Host "   https://www.python.org/downloads/" -ForegroundColor Gray
    exit 1
}

# Iniciar proxy
Write-Host ""
Write-Host "🚀 Iniciando proxy server..." -ForegroundColor Cyan
Write-Host ""

# Mudar para diretório frontend e iniciar proxy
Push-Location frontend
try {
    python proxy.py
} finally {
    Pop-Location
}
