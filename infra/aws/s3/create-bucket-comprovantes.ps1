# Script para criar bucket S3 para comprovantes de pedidos no LocalStack
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$BUCKET_NAME = "pedidos-comprovantes"

Write-Host "=== Criando Bucket S3: $BUCKET_NAME ===" -ForegroundColor Cyan

# Criar o bucket S3
Write-Host "`nCriando bucket..." -ForegroundColor Yellow

aws s3api create-bucket `
    --bucket $BUCKET_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Bucket criado com sucesso!" -ForegroundColor Green

# Verificar se o bucket foi criado
Write-Host "`nVerificando bucket..." -ForegroundColor Yellow

$buckets = aws s3api list-buckets `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$bucketExists = $buckets.Buckets | Where-Object { $_.Name -eq $BUCKET_NAME }

if ($bucketExists) {
    Write-Host "✅ Bucket encontrado na lista!" -ForegroundColor Green
    Write-Host "   Nome: $($bucketExists.Name)" -ForegroundColor Gray
    Write-Host "   Criado em: $($bucketExists.CreationDate)" -ForegroundColor Gray
} else {
    Write-Host "❌ Bucket não encontrado!" -ForegroundColor Red
    exit 1
}

# Configurar política de versionamento (opcional mas recomendado)
Write-Host "`nConfigurando versionamento..." -ForegroundColor Yellow

aws s3api put-bucket-versioning `
    --bucket $BUCKET_NAME `
    --versioning-configuration Status=Enabled `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Versionamento habilitado!" -ForegroundColor Green

# Configurar política de ciclo de vida (opcional - apagar arquivos antigos após 90 dias)
Write-Host "`nConfigurando ciclo de vida..." -ForegroundColor Yellow

$lifecyclePolicy = @{
    "Rules" = @(
        @{
            "ID" = "DeleteOldComprovantes"
            "Status" = "Enabled"
            "Expiration" = @{
                "Days" = 90
            }
            "Filter" = @{
                "Prefix" = ""
            }
        }
    )
} | ConvertTo-Json -Depth 10 -Compress

$tempFile = New-TemporaryFile
[System.IO.File]::WriteAllText($tempFile.FullName, $lifecyclePolicy)

aws s3api put-bucket-lifecycle-configuration `
    --bucket $BUCKET_NAME `
    --lifecycle-configuration "file://$($tempFile.FullName)" `
    --endpoint-url $ENDPOINT `
    --region $REGION

Remove-Item $tempFile
Write-Host "✅ Ciclo de vida configurado! (Arquivos expiram após 90 dias)" -ForegroundColor Green

# Obter URL do bucket
Write-Host "`n✅ Configuração completa!" -ForegroundColor Green
Write-Host "`nResumo:" -ForegroundColor Cyan
Write-Host "  Bucket Name: $BUCKET_NAME" -ForegroundColor White
Write-Host "  Bucket URL: http://$BUCKET_NAME.s3.localhost.localstack.cloud:4566" -ForegroundColor White
Write-Host "  Endpoint: $ENDPOINT" -ForegroundColor White
Write-Host "  Region: $REGION" -ForegroundColor White
Write-Host "  Versionamento: Habilitado" -ForegroundColor White
Write-Host "  Retenção: 90 dias" -ForegroundColor White
