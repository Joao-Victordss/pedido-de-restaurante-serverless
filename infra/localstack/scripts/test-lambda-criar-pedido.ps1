#!/usr/bin/env pwsh
# Teste da Lambda Criar Pedido

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🧪 Testando Lambda Criar Pedido" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "criar-pedido"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"

# Verificar se Lambda existe
Write-Host "Verificando se Lambda existe..." -ForegroundColor Gray
$ErrorActionPreference = "SilentlyContinue"
aws --endpoint-url=$ENDPOINT lambda get-function --function-name $LAMBDA_NAME --region $REGION 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    $ErrorActionPreference = "Stop"
    Write-Host "❌ Lambda não encontrada!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\infra\localstack\scripts\deploy-lambda-criar-pedido.ps1" -ForegroundColor Yellow
    exit 1
}
$ErrorActionPreference = "Stop"

# Criar payload de teste
$payload = @{
    body = @{
        cliente = "João Silva"
        itens = @("Pizza", "Refrigerante")
        mesa = 5
    } | ConvertTo-Json -Compress
} | ConvertTo-Json

[System.IO.File]::WriteAllText("test-payload.json", $payload, [System.Text.UTF8Encoding]::new($false))

# Invocar Lambda
Write-Host "Invocando Lambda..." -ForegroundColor Gray
aws --endpoint-url=$ENDPOINT `
    lambda invoke `
    --function-name $LAMBDA_NAME `
    --payload fileb://test-payload.json `
    --region $REGION `
    response.json

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "📥 Resposta:" -ForegroundColor Green
    $response = Get-Content response.json -Raw
    Write-Host $response -ForegroundColor Gray
    
    try {
        $responseObj = $response | ConvertFrom-Json
        
        if ($responseObj.errorMessage) {
            Write-Host ""
            Write-Host "❌ Erro: $($responseObj.errorMessage)" -ForegroundColor Red
        } elseif ($responseObj.statusCode -eq 201) {
            Write-Host ""
            Write-Host "✅ Pedido criado com sucesso!" -ForegroundColor Green
            $body = $responseObj.body | ConvertFrom-Json
            $pedidoId = $body.pedidoId
            Write-Host "   Pedido ID: $pedidoId" -ForegroundColor White
            
            # Verificar no DynamoDB
            Write-Host ""
            Write-Host "Verificando pedido no DynamoDB..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            
            $key = @{
                id = @{
                    S = $pedidoId
                }
            } | ConvertTo-Json -Compress
            
            $dbResult = aws --endpoint-url=$ENDPOINT dynamodb get-item `
                --table-name Pedidos `
                --key $key `
                --region $REGION `
                --query 'Item.{id:id.S,cliente:cliente.S,mesa:mesa.N,status:status.S}' `
                --output json
            
            Write-Host $dbResult -ForegroundColor Gray
            
            # Verificar mensagem no SQS
            Write-Host ""
            Write-Host "Verificando mensagem no SQS..." -ForegroundColor Cyan
            $sqsResult = aws --endpoint-url=$ENDPOINT sqs receive-message `
                --queue-url http://localhost:4566/000000000000/pedidos-queue `
                --region $REGION `
                --query 'Messages[0].Body' `
                --output text
            
            if ($sqsResult) {
                Write-Host $sqsResult -ForegroundColor Gray
                Write-Host ""
                Write-Host "✅ Mensagem encontrada na fila SQS!" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Resposta recebida" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Erro ao invocar Lambda" -ForegroundColor Red
}

# Limpar
Remove-Item test-payload.json -ErrorAction SilentlyContinue
Remove-Item response.json -ErrorAction SilentlyContinue

Write-Host ""
