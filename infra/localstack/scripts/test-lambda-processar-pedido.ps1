#!/usr/bin/env pwsh
# Teste da Lambda Processar Pedido

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🧪 Testando Lambda Processar Pedido" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "processar-pedido"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"

# Verificar se Lambda existe
Write-Host "Verificando se Lambda existe..." -ForegroundColor Gray
$ErrorActionPreference = "SilentlyContinue"
aws --endpoint-url=$ENDPOINT lambda get-function --function-name $LAMBDA_NAME --region $REGION 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    $ErrorActionPreference = "Stop"
    Write-Host "❌ Lambda não encontrada!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\infra\localstack\scripts\deploy-lambda-processar-pedido.ps1" -ForegroundColor Yellow
    exit 1
}
$ErrorActionPreference = "Stop"

# Criar pedido de teste no DynamoDB primeiro
$pedidoId = "pedido-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-Host "Criando pedido de teste no DynamoDB: $pedidoId" -ForegroundColor Gray

aws --endpoint-url=$ENDPOINT dynamodb put-item `
    --table-name Pedidos `
    --item "{`"id`":{`"S`":`"$pedidoId`"},`"cliente`":{`"S`":`"Maria Santos`"},`"itens`":{`"L`":[{`"S`":`"Hamburguer`"},{`"S`":`"Batata Frita`"}]},`"mesa`":{`"N`":`"10`"},`"status`":{`"S`":`"pendente`"},`"timestamp`":{`"S`":`"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')`"}}" `
    --region $REGION | Out-Null

Write-Host "✅ Pedido criado no DynamoDB" -ForegroundColor Green
Write-Host ""

# Criar payload de teste simulando mensagem SQS
$sqsEvent = @{
    Records = @(
        @{
            messageId = "test-message-001"
            receiptHandle = "test-receipt-handle"
            body = @{
                pedidoId = $pedidoId
                cliente = "Maria Santos"
                itens = @("Hamburguer", "Batata Frita")
                mesa = 10
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            } | ConvertTo-Json -Compress
        }
    )
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("test-payload.json", $sqsEvent, [System.Text.UTF8Encoding]::new($false))

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
            Write-Host ""
            Write-Host "Ver logs:" -ForegroundColor Yellow
            Write-Host "aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/processar-pedido --region us-east-1 --follow" -ForegroundColor Gray
        } elseif ($responseObj.batchItemFailures) {
            if ($responseObj.batchItemFailures.Count -eq 0) {
                Write-Host ""
                Write-Host "✅ Pedido processado com sucesso!" -ForegroundColor Green
                
                # Verificar no DynamoDB
                Write-Host ""
                Write-Host "Verificando status no DynamoDB..." -ForegroundColor Cyan
                Start-Sleep -Seconds 2
                
                $dbResult = aws --endpoint-url=$ENDPOINT dynamodb get-item `
                    --table-name Pedidos `
                    --key "{`"id`":{`"S`":`"$pedidoId`"}}" `
                    --region $REGION `
                    --query 'Item.{id:id.S,status:status.S,comprovante:comprovante_url.S}' `
                    --output json
                
                Write-Host $dbResult -ForegroundColor Gray
                
                # Verificar PDF no S3
                Write-Host ""
                Write-Host "Verificando PDF no S3..." -ForegroundColor Cyan
                $s3Key = "comprovantes/$pedidoId.pdf"
                
                $ErrorActionPreference = "SilentlyContinue"
                aws --endpoint-url=$ENDPOINT s3 ls s3://pedidos-comprovantes/$s3Key --region $REGION
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ PDF encontrado no S3!" -ForegroundColor Green
                    
                    Write-Host ""
                    Write-Host "Para baixar o PDF:" -ForegroundColor Cyan
                    Write-Host "aws --endpoint-url=http://localhost:4566 s3 cp s3://pedidos-comprovantes/$s3Key ./$pedidoId.pdf" -ForegroundColor Gray
                } else {
                    Write-Host "⚠️  PDF não encontrado no S3" -ForegroundColor Yellow
                }
                $ErrorActionPreference = "Stop"
                
            } else {
                Write-Host ""
                Write-Host "⚠️  Falhas no processamento: $($responseObj.batchItemFailures.Count)" -ForegroundColor Yellow
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
