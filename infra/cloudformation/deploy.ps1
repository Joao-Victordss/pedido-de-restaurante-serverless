#!/usr/bin/env pwsh
# Deploy da stack CloudFormation no LocalStack

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploy CloudFormation Stack - Pedidos Serverless" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Configuração
$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$STACK_NAME = "pedidos-serverless-stack"
$TEMPLATE_FILE = Join-Path $PSScriptRoot "stack.yaml"
$LAMBDA_BUCKET = "lambda-deployments"
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LAMBDAS_DIR = Join-Path $PROJECT_ROOT "src\lambdas"

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

# Verificar se o template existe
if (-not (Test-Path $TEMPLATE_FILE)) {
    Write-Host "❌ Template CloudFormation não encontrado!" -ForegroundColor Red
    Write-Host "   Caminho esperado: $TEMPLATE_FILE" -ForegroundColor Gray
    exit 1
}

Write-Host "📄 Template: $TEMPLATE_FILE" -ForegroundColor Gray
Write-Host ""

# ===========================================
# Packaging das Lambdas
# ===========================================
Write-Host "📦 Fazendo packaging das Lambdas..." -ForegroundColor Cyan

# Criar bucket S3 para lambdas se não existir
Write-Host "🪣 Criando bucket S3 para deployment de Lambdas..." -ForegroundColor Cyan
aws s3 mb "s3://$LAMBDA_BUCKET" --endpoint-url $ENDPOINT --region $REGION 2>&1 | Out-Null
Write-Host "✅ Bucket '$LAMBDA_BUCKET' pronto" -ForegroundColor Green
Write-Host ""

# Função para zipar e fazer upload de uma lambda
function Deploy-Lambda {
    param(
        [string]$LambdaName
    )
    
    Write-Host "  📁 Processando: $LambdaName" -ForegroundColor Yellow
    
    $lambdaPath = Join-Path $LAMBDAS_DIR $LambdaName
    $zipFile = Join-Path $PSScriptRoot "$LambdaName.zip"
    $tempDir = Join-Path $PSScriptRoot "temp-$LambdaName"
    
    if (-not (Test-Path $lambdaPath)) {
        Write-Host "  ❌ Código da lambda não encontrado: $lambdaPath" -ForegroundColor Red
        exit 1
    }
    
    # Remover zip e temp antigos se existirem
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    
    # Criar diretório temporário
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copiar código da lambda (excluindo __pycache__ e README)
    Write-Host "     Copiando código..." -ForegroundColor Gray
    Get-ChildItem $lambdaPath -File | Where-Object { 
        $_.Name -ne "README.md" -and $_.Extension -ne ".pyc" 
    } | ForEach-Object {
        Copy-Item $_.FullName -Destination $tempDir
    }
    
    # Instalar dependências se existir requirements.txt (exceto boto3 que já vem no runtime)
    $requirementsFile = Join-Path $lambdaPath "requirements.txt"
    if (Test-Path $requirementsFile) {
        # Criar arquivo temporário de requirements sem boto3
        $tempRequirements = Join-Path $tempDir "requirements-filtered.txt"
        Get-Content $requirementsFile | Where-Object { 
            $_ -notmatch '^\s*$' -and $_ -notmatch '^boto3' 
        } | Set-Content $tempRequirements
        
        # Verificar se há dependências além do boto3
        $requirements = Get-Content $tempRequirements
        
        if ($requirements.Count -gt 0) {
            Write-Host "     Instalando dependências (com transitive deps)..." -ForegroundColor Gray
            foreach ($req in $requirements) {
                Write-Host "       - $req" -ForegroundColor DarkGray
            }
            
            $ErrorActionPreference = "Continue"
            
            # Verificar se precisa de Pillow (bibliotecas nativas)
            $needsLinuxBuild = $requirements | Where-Object { $_ -match 'Pillow' }
            
            if ($needsLinuxBuild) {
                Write-Host "     📦 Detectado Pillow - instalando para manylinux..." -ForegroundColor Cyan
                # Instalar para plataforma Linux (manylinux) compatível com Lambda
                pip install -r $tempRequirements -t $tempDir --platform manylinux2014_x86_64 --implementation cp --python-version 39 --only-binary=:all: --upgrade --no-cache-dir 2>&1 | Out-Null
            } else {
                # Instalar normalmente (sem bibliotecas nativas)
                pip install -r $tempRequirements -t $tempDir --quiet --no-cache-dir --disable-pip-version-check 2>&1 | Out-Null
            }
            
            $ErrorActionPreference = "Stop"
            
            # Remover arquivo temporário
            Remove-Item $tempRequirements -Force
        } else {
            Write-Host "     Sem dependências extras (boto3 já incluído no runtime)" -ForegroundColor DarkGray
        }
    }
    
    # Criar zip com todo o conteúdo do temp
    Write-Host "     Compactando código..." -ForegroundColor Gray
    Push-Location $tempDir
    try {
        # Pegar todos os arquivos e diretórios exceto __pycache__ e .dist-info
        $items = Get-ChildItem -Recurse | Where-Object { 
            $_.FullName -notlike "*__pycache__*" -and 
            $_.FullName -notlike "*.dist-info*"
        }
        
        if ($items.Count -eq 0) {
            Write-Host "     ⚠️  Nenhum arquivo encontrado para compactar!" -ForegroundColor Yellow
        }
        
        # Usar compactação que preserve a estrutura de diretórios
        Compress-Archive -Path "*" -DestinationPath $zipFile -Force
    } finally {
        Pop-Location
    }
    
    # Limpar diretório temporário
    Remove-Item $tempDir -Recurse -Force
    
    # Upload para S3
    Write-Host "     Fazendo upload para S3..." -ForegroundColor Gray
    aws s3 cp $zipFile "s3://$LAMBDA_BUCKET/$LambdaName.zip" `
        --endpoint-url $ENDPOINT `
        --region $REGION | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "     ✅ Upload concluído" -ForegroundColor Green
    } else {
        Write-Host "     ❌ Erro no upload" -ForegroundColor Red
        exit 1
    }
    
    # Limpar arquivo zip local
    Remove-Item $zipFile -Force
}

# Deploy das 3 lambdas
Deploy-Lambda "criar-pedido"
Deploy-Lambda "processar-pedido"
Deploy-Lambda "listar-pedidos"

Write-Host ""
Write-Host "✅ Todas as Lambdas foram empacotadas e enviadas ao S3!" -ForegroundColor Green
Write-Host ""

# ===========================================
# Deploy do CloudFormation
# ===========================================

# Verificar se a stack já existe
Write-Host "🔍 Verificando se stack já existe..." -ForegroundColor Cyan

$stackExists = $false
try {
    $existingStack = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --endpoint-url $ENDPOINT `
        --region $REGION `
        2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $stackExists = $true
        Write-Host "⚠️  Stack '$STACK_NAME' já existe" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✅ Stack não existe, será criada" -ForegroundColor Green
}

Write-Host ""

if ($stackExists) {
    # Atualizar stack existente
    Write-Host "🔄 Atualizando stack existente..." -ForegroundColor Cyan
    
    try {
        aws cloudformation update-stack `
            --stack-name $STACK_NAME `
            --template-body "file://$TEMPLATE_FILE" `
            --endpoint-url $ENDPOINT `
            --region $REGION `
            --parameters ParameterKey=Environment,ParameterValue=dev
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Update iniciado com sucesso!" -ForegroundColor Green
            Write-Host ""
            Write-Host "⏳ Aguardando stack ser atualizada..." -ForegroundColor Yellow
            
            aws cloudformation wait stack-update-complete `
                --stack-name $STACK_NAME `
                --endpoint-url $ENDPOINT `
                --region $REGION
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Stack atualizada com sucesso!" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Timeout aguardando atualização (mas pode ter funcionado)" -ForegroundColor Yellow
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*No updates are to be performed*") {
            Write-Host "ℹ️  Nenhuma alteração detectada - Stack já está atualizada" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Erro ao atualizar stack: $errorMsg" -ForegroundColor Red
            exit 1
        }
    }
} else {
    # Criar nova stack
    Write-Host "📦 Criando stack CloudFormation..." -ForegroundColor Cyan
    
    aws cloudformation create-stack `
        --stack-name $STACK_NAME `
        --template-body "file://$TEMPLATE_FILE" `
        --endpoint-url $ENDPOINT `
        --region $REGION `
        --parameters ParameterKey=Environment,ParameterValue=dev
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao criar stack!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Criação iniciada com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ Aguardando stack ser criada..." -ForegroundColor Yellow
    
    aws cloudformation wait stack-create-complete `
        --stack-name $STACK_NAME `
        --endpoint-url $ENDPOINT `
        --region $REGION
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Stack criada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Timeout aguardando criação (mas pode ter funcionado)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Obter informações da stack
Write-Host "📊 Informações da Stack:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Gray

$stackInfo = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$stack = $stackInfo.Stacks[0]

Write-Host "  Nome: $($stack.StackName)" -ForegroundColor White
Write-Host "  Status: $($stack.StackStatus)" -ForegroundColor $(if ($stack.StackStatus -like "*COMPLETE*") { "Green" } else { "Yellow" })
Write-Host "  Criada em: $($stack.CreationTime)" -ForegroundColor Gray
Write-Host ""

# Mostrar outputs
if ($stack.Outputs) {
    Write-Host "📤 Outputs da Stack:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Gray
    
    foreach ($output in $stack.Outputs) {
        Write-Host "  $($output.OutputKey):" -ForegroundColor Yellow
        Write-Host "    $($output.OutputValue)" -ForegroundColor White
        if ($output.Description) {
            Write-Host "    ($($output.Description))" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Listar recursos criados
Write-Host "📦 Recursos Criados:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Gray

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
    
    $status = if ($resource.ResourceStatus -like "*COMPLETE*") { "✅" } else { "⚠️" }
    
    Write-Host "  $icon $status $($resource.LogicalResourceId)" -ForegroundColor White
    Write-Host "       Tipo: $($resource.ResourceType)" -ForegroundColor Gray
    Write-Host "       Status: $($resource.ResourceStatus)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "🎉 Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "💡 Comandos úteis:" -ForegroundColor Cyan
Write-Host "  # Ver detalhes da stack" -ForegroundColor Gray
Write-Host "  aws cloudformation describe-stacks --stack-name $STACK_NAME --endpoint-url $ENDPOINT --region $REGION" -ForegroundColor White
Write-Host ""
Write-Host "  # Ver outputs" -ForegroundColor Gray
Write-Host "  aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs' --endpoint-url $ENDPOINT --region $REGION" -ForegroundColor White
Write-Host ""
Write-Host "  # Deletar stack (cuidado!)" -ForegroundColor Gray
Write-Host "  .\destroy.ps1" -ForegroundColor White
Write-Host ""
