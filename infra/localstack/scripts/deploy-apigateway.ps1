#!/usr/bin/env pwsh
# Deploy API Gateway REST API

$ErrorActionPreference = "Stop"

# Configurar AWS CLI
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

Write-Host "🚀 Deploy API Gateway REST API" -ForegroundColor Cyan
Write-Host ""

$REGION = "us-east-1"
$ENDPOINT = "http://localhost:4566"
$API_NAME = "pedidos-api"

# Criar API Gateway REST API
Write-Host "📝 Criando REST API..." -ForegroundColor Cyan

# Verificar se API já existe
$existingApi = aws --endpoint-url=$ENDPOINT `
    apigateway get-rest-apis `
    --region $REGION `
    --query "items[?name=='$API_NAME'].id" `
    --output text

if ($existingApi) {
    Write-Host "Deletando API existente: $existingApi" -ForegroundColor Gray
    aws --endpoint-url=$ENDPOINT `
        apigateway delete-rest-api `
        --rest-api-id $existingApi `
        --region $REGION | Out-Null
}

# Criar nova API
Write-Host "Criando nova API..." -ForegroundColor Gray
$api = aws --endpoint-url=$ENDPOINT `
    apigateway create-rest-api `
    --name $API_NAME `
    --description "API REST para gerenciar pedidos" `
    --region $REGION | ConvertFrom-Json

$API_ID = $api.id
Write-Host "✅ API criada: $API_ID" -ForegroundColor Green

# Obter root resource
$resources = aws --endpoint-url=$ENDPOINT `
    apigateway get-resources `
    --rest-api-id $API_ID `
    --region $REGION | ConvertFrom-Json

$ROOT_RESOURCE_ID = $resources.items[0].id
Write-Host "Root resource: $ROOT_RESOURCE_ID" -ForegroundColor Gray

# Criar resource /pedidos
Write-Host "`n📁 Criando resource /pedidos..." -ForegroundColor Cyan

$pedidosResource = aws --endpoint-url=$ENDPOINT `
    apigateway create-resource `
    --rest-api-id $API_ID `
    --parent-id $ROOT_RESOURCE_ID `
    --path-part "pedidos" `
    --region $REGION | ConvertFrom-Json

$PEDIDOS_RESOURCE_ID = $pedidosResource.id
Write-Host "✅ Resource criado: $PEDIDOS_RESOURCE_ID" -ForegroundColor Green

# Criar resource /pedidos/{id}
Write-Host "`n📁 Criando resource /pedidos/{id}..." -ForegroundColor Cyan

$pedidoIdResource = aws --endpoint-url=$ENDPOINT `
    apigateway create-resource `
    --rest-api-id $API_ID `
    --parent-id $PEDIDOS_RESOURCE_ID `
    --path-part "{id}" `
    --region $REGION | ConvertFrom-Json

$PEDIDO_ID_RESOURCE_ID = $pedidoIdResource.id
Write-Host "✅ Resource criado: $PEDIDO_ID_RESOURCE_ID" -ForegroundColor Green

# Configurar método POST /pedidos
Write-Host "`n🔌 Configurando POST /pedidos..." -ForegroundColor Cyan

aws --endpoint-url=$ENDPOINT `
    apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $PEDIDOS_RESOURCE_ID `
    --http-method POST `
    --authorization-type NONE `
    --region $REGION | Out-Null

$LAMBDA_CRIAR_ARN = "arn:aws:lambda:us-east-1:000000000000:function:criar-pedido"

aws --endpoint-url=$ENDPOINT `
    apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $PEDIDOS_RESOURCE_ID `
    --http-method POST `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_CRIAR_ARN/invocations" `
    --region $REGION | Out-Null

Write-Host "✅ POST /pedidos configurado" -ForegroundColor Green

# Configurar método GET /pedidos
Write-Host "`n🔌 Configurando GET /pedidos..." -ForegroundColor Cyan

aws --endpoint-url=$ENDPOINT `
    apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $PEDIDOS_RESOURCE_ID `
    --http-method GET `
    --authorization-type NONE `
    --region $REGION | Out-Null

$LAMBDA_LISTAR_ARN = "arn:aws:lambda:us-east-1:000000000000:function:listar-pedidos"

aws --endpoint-url=$ENDPOINT `
    apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $PEDIDOS_RESOURCE_ID `
    --http-method GET `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_LISTAR_ARN/invocations" `
    --region $REGION | Out-Null

Write-Host "✅ GET /pedidos configurado" -ForegroundColor Green

# Configurar método GET /pedidos/{id}
Write-Host "`n🔌 Configurando GET /pedidos/{id}..." -ForegroundColor Cyan

aws --endpoint-url=$ENDPOINT `
    apigateway put-method `
    --rest-api-id $API_ID `
    --resource-id $PEDIDO_ID_RESOURCE_ID `
    --http-method GET `
    --authorization-type NONE `
    --region $REGION | Out-Null

aws --endpoint-url=$ENDPOINT `
    apigateway put-integration `
    --rest-api-id $API_ID `
    --resource-id $PEDIDO_ID_RESOURCE_ID `
    --http-method GET `
    --type AWS_PROXY `
    --integration-http-method POST `
    --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_LISTAR_ARN/invocations" `
    --region $REGION | Out-Null

Write-Host "✅ GET /pedidos/{id} configurado" -ForegroundColor Green

# Fazer deploy
Write-Host "`n🚢 Fazendo deploy para stage 'prod'..." -ForegroundColor Cyan

aws --endpoint-url=$ENDPOINT `
    apigateway create-deployment `
    --rest-api-id $API_ID `
    --stage-name prod `
    --region $REGION | Out-Null

Write-Host "✅ Deploy completo!" -ForegroundColor Green

# Imprimir URLs
Write-Host ""
Write-Host "🌐 API Gateway URL:" -ForegroundColor Cyan
Write-Host "   http://localhost:4566/restapis/$API_ID/prod/_user_request_" -ForegroundColor Gray
Write-Host ""
Write-Host "📍 Endpoints disponíveis:" -ForegroundColor Cyan
Write-Host "   POST http://localhost:4566/restapis/$API_ID/prod/_user_request_/pedidos" -ForegroundColor Yellow
Write-Host "   GET  http://localhost:4566/restapis/$API_ID/prod/_user_request_/pedidos" -ForegroundColor Yellow
Write-Host "   GET  http://localhost:4566/restapis/$API_ID/prod/_user_request_/pedidos/{id}" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Para testar a API:" -ForegroundColor Cyan
Write-Host "   .\infra\localstack\scripts\test-apigateway.ps1 $API_ID" -ForegroundColor Gray

# Salvar API ID em arquivo
$API_ID | Out-File -FilePath "api-id.txt" -Encoding UTF8
Write-Host ""
Write-Host "💾 API ID salvo em: api-id.txt" -ForegroundColor Green
