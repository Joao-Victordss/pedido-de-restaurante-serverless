# Script de teste para a tabela Pedidos
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$TABLE_NAME = "Pedidos"

Write-Host "=== Testando Tabela DynamoDB: Pedidos ===" -ForegroundColor Cyan

# 1. Inserir um pedido de exemplo
Write-Host "`n1. Inserindo pedido de exemplo..." -ForegroundColor Yellow
$pedidoId = "pedido-" + (Get-Date -Format "yyyyMMddHHmmss")
$timestamp = Get-Date -Format o

$itemJson = @{
    "id" = @{"S" = $pedidoId}
    "cliente" = @{"S" = "João Silva"}
    "itens" = @{"L" = @(
        @{"S" = "Pizza Margherita"},
        @{"S" = "Refrigerante"}
    )}
    "mesa" = @{"N" = "5"}
    "status" = @{"S" = "pendente"}
    "timestamp" = @{"S" = $timestamp}
} | ConvertTo-Json -Depth 10 -Compress

$tempFile = New-TemporaryFile
[System.IO.File]::WriteAllText($tempFile.FullName, $itemJson)

aws dynamodb put-item `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME `
  --item "file://$($tempFile.FullName)"

Remove-Item $tempFile
Write-Host "✅ Pedido inserido com ID: $pedidoId" -ForegroundColor Green

# 2. Consultar o pedido inserido
Write-Host "`n2. Consultando pedido..." -ForegroundColor Yellow

$keyJson = @{
    "id" = @{"S" = $pedidoId}
} | ConvertTo-Json -Depth 10 -Compress

$tempFile = New-TemporaryFile
[System.IO.File]::WriteAllText($tempFile.FullName, $keyJson)

aws dynamodb get-item `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME `
  --key "file://$($tempFile.FullName)"

Remove-Item $tempFile

# 3. Listar todos os pedidos
Write-Host "`n3. Listando todos os pedidos..." -ForegroundColor Yellow
aws dynamodb scan `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME

# 4. Atualizar status do pedido
Write-Host "`n4. Atualizando status para 'em_preparo'..." -ForegroundColor Yellow

$keyJson = @{
    "id" = @{"S" = $pedidoId}
} | ConvertTo-Json -Depth 10 -Compress

$valuesJson = @{
    ":status" = @{"S" = "em_preparo"}
} | ConvertTo-Json -Depth 10 -Compress

$namesJson = @{
    "#status" = "status"
} | ConvertTo-Json -Depth 10 -Compress

$tempKey = New-TemporaryFile
$tempValues = New-TemporaryFile
$tempNames = New-TemporaryFile

[System.IO.File]::WriteAllText($tempKey.FullName, $keyJson)
[System.IO.File]::WriteAllText($tempValues.FullName, $valuesJson)
[System.IO.File]::WriteAllText($tempNames.FullName, $namesJson)

aws dynamodb update-item `
  --endpoint-url $ENDPOINT `
  --region $REGION `
  --table-name $TABLE_NAME `
  --key "file://$($tempKey.FullName)" `
  --update-expression "SET #status = :status" `
  --expression-attribute-names "file://$($tempNames.FullName)" `
  --expression-attribute-values "file://$($tempValues.FullName)" `
  --return-values ALL_NEW

Remove-Item $tempKey, $tempValues, $tempNames

Write-Host "`n✅ Testes concluídos!" -ForegroundColor Green
