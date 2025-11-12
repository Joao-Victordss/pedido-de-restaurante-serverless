#!/usr/bin/env pwsh
# Script para provisionar todos os recursos AWS no LocalStack
# Executa os scripts de criação de cada serviço em ordem

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando deploy de todos os recursos AWS..." -ForegroundColor Cyan
Write-Host ""

# Diretório base
$baseDir = Split-Path -Parent $PSScriptRoot
$awsDir = Join-Path $baseDir "aws"

# Verificar se LocalStack está rodando
Write-Host "🔍 Verificando LocalStack..." -ForegroundColor Yellow
try {
    $health = aws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1 2>&1
    Write-Host "✅ LocalStack está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack não está rodando!" -ForegroundColor Red
    Write-Host "Execute: make up" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 1. DynamoDB - Tabela Pedidos
Write-Host "📊 [1/4] Criando tabela DynamoDB Pedidos..." -ForegroundColor Cyan
$dynamoScript = Join-Path $awsDir "dynamodb\create-table-pedidos.ps1"
if (Test-Path $dynamoScript) {
    & $dynamoScript
    Write-Host "✅ Tabela DynamoDB criada com sucesso" -ForegroundColor Green
} else {
    Write-Host "⚠️ Script não encontrado: $dynamoScript" -ForegroundColor Yellow
}
Write-Host ""

# 2. SQS - Fila de Pedidos
Write-Host "📬 [2/4] Criando fila SQS pedidos-queue..." -ForegroundColor Cyan
$sqsScript = Join-Path $awsDir "sqs\create-queue-pedidos.ps1"
if (Test-Path $sqsScript) {
    & $sqsScript
    Write-Host "✅ Fila SQS criada com sucesso" -ForegroundColor Green
} else {
    Write-Host "⚠️ Script não encontrado: $sqsScript" -ForegroundColor Yellow
}
Write-Host ""

# 3. S3 - Bucket de Comprovantes
Write-Host "🪣 [3/4] Criando bucket S3 pedidos-comprovantes..." -ForegroundColor Cyan
$s3Script = Join-Path $awsDir "s3\create-bucket-comprovantes.ps1"
if (Test-Path $s3Script) {
    & $s3Script
    Write-Host "✅ Bucket S3 criado com sucesso" -ForegroundColor Green
} else {
    Write-Host "⚠️ Script não encontrado: $s3Script" -ForegroundColor Yellow
}
Write-Host ""

# 4. SNS - Tópico de Pedidos Concluídos
Write-Host "📢 [4/4] Criando tópico SNS PedidosConcluidos..." -ForegroundColor Cyan
$snsScript = Join-Path $awsDir "sns\create-topic-pedidos.ps1"
if (Test-Path $snsScript) {
    & $snsScript
    Write-Host "✅ Tópico SNS criado com sucesso" -ForegroundColor Green
} else {
    Write-Host "⚠️ Script não encontrado: $snsScript" -ForegroundColor Yellow
}
Write-Host ""

# Resumo
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "🎉 Deploy completo!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "Recursos provisionados:" -ForegroundColor White
Write-Host "  📊 DynamoDB: Pedidos" -ForegroundColor White
Write-Host "  📬 SQS: pedidos-queue (com DLQ)" -ForegroundColor White
Write-Host "  🪣 S3: pedidos-comprovantes" -ForegroundColor White
Write-Host "  📢 SNS: PedidosConcluidos" -ForegroundColor White
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Testar recursos: ./infra/aws/{serviço}/test-*.ps1" -ForegroundColor Gray
Write-Host "  2. Implementar Lambdas: ./src/lambdas/" -ForegroundColor Gray
Write-Host "  3. Configurar API Gateway" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentação completa: ./docs/setup.md" -ForegroundColor Cyan
