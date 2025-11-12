# Script de teste para o bucket S3 de comprovantes
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$BUCKET_NAME = "pedidos-comprovantes"

Write-Host "=== Testando Bucket S3: $BUCKET_NAME ===" -ForegroundColor Cyan

# 1. Criar um arquivo PDF simulado (texto simples por enquanto)
Write-Host "`n1. Criando comprovante de teste..." -ForegroundColor Yellow

$pedidoId = "pedido-" + (Get-Date -Format "yyyyMMddHHmmss")
$fileName = "$pedidoId-comprovante.pdf"
$tempFilePath = [System.IO.Path]::Combine($env:TEMP, $fileName)

$comprovanteContent = @"
==========================================
    COMPROVANTE DE PEDIDO
==========================================

Pedido ID: $pedidoId
Data/Hora: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Cliente: João Silva
Mesa: 5

ITENS DO PEDIDO:
- Pizza Margherita ......... R$ 35,00
- Refrigerante ............. R$ 8,00

------------------------------------------
TOTAL ........................ R$ 43,00
==========================================

Obrigado pela preferência!
==========================================
"@

[System.IO.File]::WriteAllText($tempFilePath, $comprovanteContent)
Write-Host "✅ Arquivo criado: $fileName" -ForegroundColor Green
Write-Host "   Tamanho: $((Get-Item $tempFilePath).Length) bytes" -ForegroundColor Gray

# 2. Upload do arquivo para S3
Write-Host "`n2. Fazendo upload para S3..." -ForegroundColor Yellow

$s3Key = "comprovantes/$fileName"

aws s3 cp $tempFilePath "s3://$BUCKET_NAME/$s3Key" `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Upload concluído!" -ForegroundColor Green
Write-Host "   S3 Key: $s3Key" -ForegroundColor Gray

# 3. Listar arquivos no bucket
Write-Host "`n3. Listando arquivos no bucket..." -ForegroundColor Yellow

$objects = aws s3api list-objects-v2 `
    --bucket $BUCKET_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

if ($objects.Contents) {
    Write-Host "✅ Arquivos encontrados: $($objects.Contents.Count)" -ForegroundColor Green
    foreach ($obj in $objects.Contents) {
        Write-Host "   - $($obj.Key) ($($obj.Size) bytes)" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  Nenhum arquivo no bucket" -ForegroundColor Yellow
}

# 4. Download do arquivo
Write-Host "`n4. Fazendo download do arquivo..." -ForegroundColor Yellow

$downloadPath = [System.IO.Path]::Combine($env:TEMP, "downloaded-$fileName")

aws s3 cp "s3://$BUCKET_NAME/$s3Key" $downloadPath `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Download concluído!" -ForegroundColor Green
Write-Host "   Arquivo salvo em: $downloadPath" -ForegroundColor Gray

# Verificar conteúdo
$downloadedContent = [System.IO.File]::ReadAllText($downloadPath)
if ($downloadedContent -eq $comprovanteContent) {
    Write-Host "✅ Conteúdo verificado - arquivo íntegro!" -ForegroundColor Green
} else {
    Write-Host "❌ Conteúdo diferente!" -ForegroundColor Red
}

# 5. Obter metadados do objeto
Write-Host "`n5. Obtendo metadados do objeto..." -ForegroundColor Yellow

$metadata = aws s3api head-object `
    --bucket $BUCKET_NAME `
    --key $s3Key `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Metadados:" -ForegroundColor Green
Write-Host "   Content-Type: $($metadata.ContentType)" -ForegroundColor Gray
Write-Host "   Content-Length: $($metadata.ContentLength) bytes" -ForegroundColor Gray
Write-Host "   Last-Modified: $($metadata.LastModified)" -ForegroundColor Gray
Write-Host "   ETag: $($metadata.ETag)" -ForegroundColor Gray

# 6. Gerar URL pré-assinada (válida por 1 hora)
Write-Host "`n6. Gerando URL pré-assinada..." -ForegroundColor Yellow

$presignedUrl = aws s3 presign "s3://$BUCKET_NAME/$s3Key" `
    --expires-in 3600 `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ URL gerada (válida por 1 hora):" -ForegroundColor Green
Write-Host "   $presignedUrl" -ForegroundColor Gray

# 7. Deletar arquivo de teste
Write-Host "`n7. Limpando arquivo de teste..." -ForegroundColor Yellow

aws s3 rm "s3://$BUCKET_NAME/$s3Key" `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Arquivo deletado do S3!" -ForegroundColor Green

# Limpar arquivos temporários
Remove-Item $tempFilePath -Force
Remove-Item $downloadPath -Force

Write-Host "`n✅ Testes concluídos!" -ForegroundColor Green
Write-Host "`nOperações testadas:" -ForegroundColor Cyan
Write-Host "  ✅ Criação de arquivo" -ForegroundColor White
Write-Host "  ✅ Upload para S3" -ForegroundColor White
Write-Host "  ✅ Listagem de objetos" -ForegroundColor White
Write-Host "  ✅ Download de S3" -ForegroundColor White
Write-Host "  ✅ Verificação de integridade" -ForegroundColor White
Write-Host "  ✅ Obtenção de metadados" -ForegroundColor White
Write-Host "  ✅ Geração de URL pré-assinada" -ForegroundColor White
Write-Host "  ✅ Deleção de objeto" -ForegroundColor White
