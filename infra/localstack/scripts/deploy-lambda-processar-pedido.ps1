#!/usr/bin/env pwsh
# Deploy Lambda Processar Pedido para LocalStack

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🚀 Deploy Lambda Processar Pedido" -ForegroundColor Cyan
Write-Host ""

$LAMBDA_NAME = "processar-pedido"
$LAMBDA_DIR = Resolve-Path "src/lambdas/processar-pedido"
$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"
$SQS_QUEUE_URL = "http://localhost:4566/000000000000/pedidos-queue"

# 1. Criar função Lambda
Write-Host "📝 Criando Lambda..." -ForegroundColor Cyan

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

# Criar Lambda com configurações para LocalStack
$result = aws --endpoint-url=$ENDPOINT `
    lambda create-function `
    --function-name $LAMBDA_NAME `
    --runtime python3.11 `
    --role arn:aws:iam::000000000000:role/lambda-role `
    --handler index.handler `
    --zip-file fileb://simple.zip `
    --region $REGION `
    --timeout 60 `
    --environment "Variables={AWS_ACCESS_KEY_ID=test,AWS_SECRET_ACCESS_KEY=test,AWS_DEFAULT_REGION=us-east-1,LOCALSTACK_HOSTNAME=host.docker.internal,DYNAMODB_TABLE=Pedidos,S3_BUCKET=pedidos-comprovantes,SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:PedidosConcluidos}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao criar Lambda" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda criada: $LAMBDA_NAME" -ForegroundColor Green
Write-Host ""

# Limpar
Remove-Item "simple.zip" -ErrorAction SilentlyContinue

Set-Location "../../.."

# 2. Configurar trigger SQS
Write-Host "🔗 Configurando trigger SQS..." -ForegroundColor Cyan

# Obter ARN da fila SQS
$queueArn = "arn:aws:sqs:us-east-1:000000000000:pedidos-queue"

# Verificar se event source mapping já existe
$ErrorActionPreference = "SilentlyContinue"
$mappings = aws --endpoint-url=$ENDPOINT lambda list-event-source-mappings --function-name $LAMBDA_NAME --region $REGION 2>$null
$ErrorActionPreference = "Stop"

if ($mappings) {
    $mappingsObj = $mappings | ConvertFrom-Json
    if ($mappingsObj.EventSourceMappings.Count -gt 0) {
        Write-Host "Removendo event source mapping existente..." -ForegroundColor Gray
        foreach ($mapping in $mappingsObj.EventSourceMappings) {
            aws --endpoint-url=$ENDPOINT lambda delete-event-source-mapping --uuid $mapping.UUID --region $REGION | Out-Null
        }
    }
}

Write-Host "Criando event source mapping..." -ForegroundColor Gray

# Criar event source mapping (trigger SQS)
aws --endpoint-url=$ENDPOINT `
    lambda create-event-source-mapping `
    --function-name $LAMBDA_NAME `
    --event-source-arn $queueArn `
    --batch-size 10 `
    --region $REGION

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Trigger SQS configurado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Aviso: Não foi possível configurar trigger SQS" -ForegroundColor Yellow
    Write-Host "   Isso é normal no LocalStack, a Lambda ainda pode ser testada manualmente" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🧪 Testando Lambda..." -ForegroundColor Cyan
Write-Host ""

# Criar payload de teste simulando mensagem SQS
$sqsEvent = @{
    Records = @(
        @{
            messageId = "test-message-001"
            receiptHandle = "test-receipt-handle"
            body = @{
                pedidoId = "pedido-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
                cliente = "Maria Santos"
                itens = @("Hamburguer", "Batata Frita", "Refrigerante")
                mesa = 10
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            } | ConvertTo-Json -Compress
        }
    )
} | ConvertTo-Json -Depth 10

[System.IO.File]::WriteAllText("test-payload.json", $sqsEvent, [System.Text.UTF8Encoding]::new($false))

Start-Sleep -Seconds 3

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
        } elseif ($responseObj.batchItemFailures) {
            if ($responseObj.batchItemFailures.Count -eq 0) {
                Write-Host ""
                Write-Host "✅ Pedido processado com sucesso!" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "⚠️  Falhas no processamento: $($responseObj.batchItemFailures.Count)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Resposta recebida" -ForegroundColor Gray
    }
}

# Limpar
Remove-Item test-payload.json -ErrorAction SilentlyContinue
Remove-Item response.json -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "🎉 Deploy completo!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Para testar o fluxo completo:" -ForegroundColor Cyan
Write-Host "   1. Envie uma mensagem para a fila SQS (ou use a Lambda criar-pedido)" -ForegroundColor Gray
Write-Host "   2. Verifique os logs da Lambda" -ForegroundColor Gray
Write-Host "   3. Confira o PDF no S3" -ForegroundColor Gray
Write-Host "   4. Valide o status no DynamoDB" -ForegroundColor Gray
