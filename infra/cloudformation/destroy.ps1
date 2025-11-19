#!/usr/bin/env pwsh
# Destroy da stack CloudFormation no LocalStack

$ErrorActionPreference = "Stop"

Write-Host "🗑️  Destroy CloudFormation Stack - Pedidos Serverless" -ForegroundColor Red
Write-Host "======================================================" -ForegroundColor Red
Write-Host ""

# Configuração
$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$STACK_NAME = "pedidos-serverless-stack"

# Configurar credenciais AWS (necessário para LocalStack)
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"

# Verificar se LocalStack está rodando
Write-Host "🔍 Verificando LocalStack..." -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "$ENDPOINT/_localstack/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ LocalStack está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack não está rodando!" -ForegroundColor Red
    Write-Host "   Execute: docker compose -f infra/docker-compose.yml up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Verificar se a stack existe
Write-Host "🔍 Verificando se stack existe..." -ForegroundColor Cyan

$stackExists = $false
$stackStatus = ""

try {
    $stackInfo = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --endpoint-url $ENDPOINT `
        --region $REGION `
        --output json 2>&1 | ConvertFrom-Json
    
    if ($LASTEXITCODE -eq 0) {
        $stackExists = $true
        $stackStatus = $stackInfo.Stacks[0].StackStatus
        Write-Host "✅ Stack encontrada: $STACK_NAME" -ForegroundColor Green
        Write-Host "   Status: $stackStatus" -ForegroundColor Gray
    }
} catch {
    Write-Host "ℹ️  Stack '$STACK_NAME' não existe ou já foi deletada" -ForegroundColor Cyan
    exit 0
}

Write-Host ""

if (-not $stackExists) {
    Write-Host "ℹ️  Nada para deletar - Stack não existe" -ForegroundColor Cyan
    exit 0
}

# Listar recursos que serão deletados
Write-Host "📦 Recursos que serão DELETADOS:" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

$resources = aws cloudformation list-stack-resources `
    --stack-name $STACK_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

foreach ($resource in $resources.StackResourceSummaries) {
    $icon = switch ($resource.ResourceType) {
        "AWS::DynamoDB::Table" { "📊" }
        "AWS::SQS::Queue" { "📬" }
        "AWS::S3::Bucket" { "🪣" }
        "AWS::SNS::Topic" { "📢" }
        "AWS::SNS::Subscription" { "📧" }
        default { "📦" }
    }
    
    Write-Host "  $icon $($resource.LogicalResourceId)" -ForegroundColor Red
    Write-Host "       Tipo: $($resource.ResourceType)" -ForegroundColor Gray
    Write-Host "       ID Físico: $($resource.PhysicalResourceId)" -ForegroundColor Gray
    Write-Host ""
}

# Confirmação
Write-Host "⚠️  ATENÇÃO: Esta ação é DESTRUTIVA!" -ForegroundColor Red
Write-Host "   Todos os recursos acima serão PERMANENTEMENTE deletados." -ForegroundColor Yellow
Write-Host "   Isso inclui:" -ForegroundColor Yellow
Write-Host "   - Tabela DynamoDB com TODOS os pedidos" -ForegroundColor Yellow
Write-Host "   - Bucket S3 com TODOS os comprovantes" -ForegroundColor Yellow
Write-Host "   - Filas SQS com mensagens pendentes" -ForegroundColor Yellow
Write-Host "   - Tópico SNS e subscriptions" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Digite 'DELETAR' para confirmar a destruição da stack"

if ($confirmation -ne "DELETAR") {
    Write-Host ""
    Write-Host "❌ Operação cancelada pelo usuário" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🗑️  Deletando stack..." -ForegroundColor Red

# Deletar a stack
aws cloudformation delete-stack `
    --stack-name $STACK_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao deletar stack!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Deleção iniciada com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "⏳ Aguardando stack ser deletada..." -ForegroundColor Yellow

# Aguardar deleção (com timeout)
$maxWait = 300  # 5 minutos
$elapsed = 0
$checkInterval = 5

while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
    
    try {
        $stackInfo = aws cloudformation describe-stacks `
            --stack-name $STACK_NAME `
            --endpoint-url $ENDPOINT `
            --region $REGION `
            --output json 2>&1 | ConvertFrom-Json
        
        if ($LASTEXITCODE -eq 0) {
            $currentStatus = $stackInfo.Stacks[0].StackStatus
            Write-Host "   Status: $currentStatus (${elapsed}s)" -ForegroundColor Gray
            
            if ($currentStatus -like "*FAILED*") {
                Write-Host ""
                Write-Host "❌ Deleção falhou!" -ForegroundColor Red
                Write-Host "   Status final: $currentStatus" -ForegroundColor Red
                exit 1
            }
        } else {
            # Stack não existe mais
            break
        }
    } catch {
        # Stack foi deletada
        break
    }
}

Write-Host ""

# Verificar se foi deletada com sucesso
try {
    aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --endpoint-url $ENDPOINT `
        --region $REGION 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "======================================================" -ForegroundColor Green
        Write-Host "✅ Stack deletada com sucesso!" -ForegroundColor Green
        Write-Host "======================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Todos os recursos foram removidos:" -ForegroundColor Gray
        Write-Host "  📊 Tabela DynamoDB: Pedidos" -ForegroundColor Gray
        Write-Host "  📬 Filas SQS: pedidos-queue + DLQ" -ForegroundColor Gray
        Write-Host "  🪣 Bucket S3: pedidos-comprovantes" -ForegroundColor Gray
        Write-Host "  📢 Tópico SNS: PedidosConcluidos" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "⚠️  Stack ainda existe após timeout" -ForegroundColor Yellow
        Write-Host "   Verifique manualmente o status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "✅ Stack deletada com sucesso!" -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
}

Write-Host ""
Write-Host "💡 Para recriar a stack, execute:" -ForegroundColor Cyan
Write-Host "   .\deploy.ps1" -ForegroundColor White
Write-Host ""
