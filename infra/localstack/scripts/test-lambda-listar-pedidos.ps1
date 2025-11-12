#!/usr/bin/env pwsh
# Testar Lambda Listar Pedidos

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🧪 Testando Lambda Listar Pedidos" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "listar-pedidos"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"

# Teste 1: Listar todos os pedidos
Write-Host "📋 Teste 1: GET /pedidos (listar todos)" -ForegroundColor Cyan

$payload1 = '{\"httpMethod\":\"GET\",\"path\":\"/pedidos\",\"queryStringParameters\":{\"limit\":\"5\"}}'

Write-Host "Invocando Lambda..." -ForegroundColor Gray

aws --endpoint-url=$ENDPOINT `
    lambda invoke `
    --function-name $LAMBDA_NAME `
    --payload $payload1 `
    --region $REGION `
    --cli-binary-format raw-in-base64-out `
    response1.txt

Write-Host "Resposta Lambda:" -ForegroundColor Gray
$response1Content = Get-Content response1.txt -Raw
$response1Content | ConvertFrom-Json | ConvertTo-Json -Depth 10

Write-Host ""

# Teste 2: Buscar pedido específico
Write-Host "🔍 Teste 2: GET /pedidos/{id} (buscar específico)" -ForegroundColor Cyan

# Primeiro, vamos listar para pegar um ID
$response1 = $response1Content | ConvertFrom-Json
$body = $response1.body | ConvertFrom-Json

if ($body.pedidos -and $body.pedidos.Count -gt 0) {
    $pedidoId = $body.pedidos[0].pedidoId
    Write-Host "Testando com pedidoId: $pedidoId" -ForegroundColor Gray
    
    $payload2 = '{\"httpMethod\":\"GET\",\"path\":\"/pedidos/' + $pedidoId + '\",\"pathParameters\":{\"id\":\"' + $pedidoId + '\"}}'
    
    Write-Host "Invocando Lambda..." -ForegroundColor Gray
    
    aws --endpoint-url=$ENDPOINT `
        lambda invoke `
        --function-name $LAMBDA_NAME `
        --payload $payload2 `
        --region $REGION `
        --cli-binary-format raw-in-base64-out `
        response2.txt
    
    Write-Host "Resposta Lambda:" -ForegroundColor Gray
    Get-Content response2.txt -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 10
    
    Remove-Item response2.txt -ErrorAction SilentlyContinue
} else {
    Write-Host "⚠️  Nenhum pedido encontrado para testar GET por ID" -ForegroundColor Yellow
}

Write-Host ""

# Teste 3: Filtrar por status
Write-Host "🎯 Teste 3: GET /pedidos?status=processado (filtrar)" -ForegroundColor Cyan

$payload3 = '{\"httpMethod\":\"GET\",\"path\":\"/pedidos\",\"queryStringParameters\":{\"status\":\"processado\",\"limit\":\"3\"}}'

Write-Host "Invocando Lambda..." -ForegroundColor Gray

aws --endpoint-url=$ENDPOINT `
    lambda invoke `
    --function-name $LAMBDA_NAME `
    --payload $payload3 `
    --region $REGION `
    --cli-binary-format raw-in-base64-out `
    response3.txt

Write-Host "Resposta Lambda:" -ForegroundColor Gray
Get-Content response3.txt -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Limpar
Remove-Item response1.txt -ErrorAction SilentlyContinue
Remove-Item response3.txt -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Testes completos!" -ForegroundColor Green
