#!/usr/bin/env pwsh
# Testar API Gateway

param(
    [string]$ApiId
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Testando API Gateway REST" -ForegroundColor Cyan
Write-Host ""

# Se API ID não foi passado, tentar ler do arquivo
if (-not $ApiId) {
    if (Test-Path "api-id.txt") {
        $ApiId = Get-Content "api-id.txt" -Raw | ForEach-Object { $_.Trim() }
        Write-Host "API ID lido do arquivo: $ApiId" -ForegroundColor Gray
    } else {
        Write-Host "❌ Erro: API ID não especificado e arquivo api-id.txt não encontrado" -ForegroundColor Red
        Write-Host "Uso: .\test-apigateway.ps1 <API_ID>" -ForegroundColor Yellow
        exit 1
    }
}

$BASE_URL = "http://localhost:4566/restapis/$ApiId/prod/_user_request_"

# Teste 1: POST /pedidos (criar pedido)
Write-Host "📝 Teste 1: POST /pedidos (criar pedido)" -ForegroundColor Cyan

$body = @{
    cliente = "Maria Santos"
    mesa = 15
    itens = @("Hamburguer", "Batata Frita", "Coca Cola")
} | ConvertTo-Json

Write-Host "Body: $body" -ForegroundColor Gray

$response1 = Invoke-WebRequest -Uri "$BASE_URL/pedidos" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body `
    -UseBasicParsing

Write-Host "Status: $($response1.StatusCode)" -ForegroundColor Gray
Write-Host "Resposta:" -ForegroundColor Gray
$response1.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10

$pedidoId = ($response1.Content | ConvertFrom-Json).pedidoId
Write-Host "✅ Pedido criado: $pedidoId" -ForegroundColor Green

Write-Host ""

# Teste 2: GET /pedidos (listar todos)
Write-Host "📋 Teste 2: GET /pedidos (listar todos)" -ForegroundColor Cyan

$response2 = Invoke-WebRequest -Uri "$BASE_URL/pedidos?limit=5" `
    -Method GET `
    -UseBasicParsing

Write-Host "Status: $($response2.StatusCode)" -ForegroundColor Gray
Write-Host "Resposta:" -ForegroundColor Gray
$response2.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10

Write-Host ""

# Teste 3: GET /pedidos/{id} (buscar específico)
Write-Host "🔍 Teste 3: GET /pedidos/{id} (buscar específico)" -ForegroundColor Cyan
Write-Host "Buscando pedido: $pedidoId" -ForegroundColor Gray

$response3 = Invoke-WebRequest -Uri "$BASE_URL/pedidos/$pedidoId" `
    -Method GET `
    -UseBasicParsing

Write-Host "Status: $($response3.StatusCode)" -ForegroundColor Gray
Write-Host "Resposta:" -ForegroundColor Gray
$response3.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10

Write-Host ""

# Teste 4: GET /pedidos?status=processado (filtrar)
Write-Host "🎯 Teste 4: GET /pedidos?status=processado (filtrar)" -ForegroundColor Cyan

$response4 = Invoke-WebRequest -Uri "$BASE_URL/pedidos?status=processado&limit=3" `
    -Method GET `
    -UseBasicParsing

Write-Host "Status: $($response4.StatusCode)" -ForegroundColor Gray
Write-Host "Resposta:" -ForegroundColor Gray
$response4.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "✅ Todos os testes completos!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Endpoints testados:" -ForegroundColor Cyan
Write-Host "   ✓ POST /pedidos" -ForegroundColor Green
Write-Host "   ✓ GET /pedidos" -ForegroundColor Green
Write-Host "   ✓ GET /pedidos/{id}" -ForegroundColor Green
Write-Host "   ✓ GET /pedidos?status=..." -ForegroundColor Green
