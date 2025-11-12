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

# 1. Instalar dependências e criar pacote
Write-Host "� Instalando dependências..." -ForegroundColor Cyan

Set-Location $LAMBDA_DIR

# Criar diretório temporário para build
if (Test-Path "package") { Remove-Item "package" -Recurse -Force }
New-Item -ItemType Directory -Path "package" | Out-Null

# Instalar dependências no diretório package
Write-Host "Instalando fpdf2..." -ForegroundColor Gray
pip install --target ./package fpdf2 -q

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências" -ForegroundColor Red
    exit 1
}

# Copiar código da Lambda
Copy-Item "index.py" -Destination "package/"

# Criar ZIP
Write-Host "Criando arquivo ZIP..." -ForegroundColor Gray
Set-Location "package"
if (Test-Path "../lambda.zip") { Remove-Item "../lambda.zip" }
Compress-Archive -Path * -DestinationPath "../lambda.zip" -Force
Set-Location ..

Write-Host "✅ Pacote criado: lambda.zip" -ForegroundColor Green
Write-Host ""

# 2. Criar função Lambda
Write-Host "📝 Criando Lambda..." -ForegroundColor Cyan

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
    --zip-file fileb://lambda.zip `
    --region $REGION `
    --timeout 60 `
    --memory-size 512 `
    --environment "Variables={AWS_ACCESS_KEY_ID=test,AWS_SECRET_ACCESS_KEY=test,AWS_DEFAULT_REGION=us-east-1,LOCALSTACK_HOSTNAME=host.docker.internal,DYNAMODB_TABLE=Pedidos,S3_BUCKET=pedidos-comprovantes,SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:PedidosConcluidos}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao criar Lambda" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Lambda criada: $LAMBDA_NAME" -ForegroundColor Green
Write-Host ""

# Limpar
Remove-Item "package" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "lambda.zip" -ErrorAction SilentlyContinue

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
Write-Host "🎉 Deploy completo!" -ForegroundColor Green
Write-Host ""
Write-Host "� Para testar a Lambda:" -ForegroundColor Cyan
Write-Host "   .\infra\localstack\scripts\test-lambda-processar-pedido.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Para testar o fluxo completo:" -ForegroundColor Cyan
Write-Host "   1. Execute: .\infra\localstack\scripts\test-lambda-criar-pedido.ps1" -ForegroundColor Gray
Write-Host "   2. Aguarde alguns segundos" -ForegroundColor Gray
Write-Host "   3. Verifique os logs, S3 e DynamoDB" -ForegroundColor Gray
