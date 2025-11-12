# Script de teste para a fila SQS Pedidos
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$QUEUE_NAME = "pedidos-queue"

Write-Host "=== Testando Fila SQS: $QUEUE_NAME ===" -ForegroundColor Cyan

# Obter URL da fila
Write-Host "`nObtendo URL da fila..." -ForegroundColor Yellow
$queueUrlResult = aws sqs get-queue-url `
    --queue-name $QUEUE_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$queueUrl = $queueUrlResult.QueueUrl
Write-Host "✅ Queue URL: $queueUrl" -ForegroundColor Green

# 1. Enviar mensagem para a fila
Write-Host "`n1. Enviando mensagem de pedido para a fila..." -ForegroundColor Yellow

$pedidoId = "pedido-" + (Get-Date -Format "yyyyMMddHHmmss")
$messageBody = @{
    "pedidoId" = $pedidoId
    "acao" = "processar_pedido"
    "dados" = @{
        "cliente" = "Maria Santos"
        "mesa" = 10
        "itens" = @("Hambúrguer", "Batata Frita", "Suco")
        "total" = 45.50
    }
    "timestamp" = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 10 -Compress

$tempFile = New-TemporaryFile
[System.IO.File]::WriteAllText($tempFile.FullName, $messageBody)

$sendResult = aws sqs send-message `
    --queue-url $queueUrl `
    --message-body "file://$($tempFile.FullName)" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Remove-Item $tempFile

Write-Host "✅ Mensagem enviada!" -ForegroundColor Green
Write-Host "   Message ID: $($sendResult.MessageId)" -ForegroundColor Gray
Write-Host "   Pedido ID: $pedidoId" -ForegroundColor Gray

# 2. Verificar atributos da fila
Write-Host "`n2. Verificando atributos da fila..." -ForegroundColor Yellow

$attributes = aws sqs get-queue-attributes `
    --queue-url $queueUrl `
    --attribute-names All `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Atributos da fila:" -ForegroundColor Green
Write-Host "   Mensagens disponíveis: $($attributes.Attributes.ApproximateNumberOfMessages)" -ForegroundColor Gray

# 3. Receber mensagem da fila
Write-Host "`n3. Recebendo mensagem da fila..." -ForegroundColor Yellow

$receiveResult = aws sqs receive-message `
    --queue-url $queueUrl `
    --max-number-of-messages 1 `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

if ($receiveResult.Messages) {
    $message = $receiveResult.Messages[0]
    Write-Host "✅ Mensagem recebida!" -ForegroundColor Green
    Write-Host "   Message ID: $($message.MessageId)" -ForegroundColor Gray
    Write-Host "   Receipt Handle: $($message.ReceiptHandle.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "`n   Corpo da mensagem:" -ForegroundColor Cyan
    $message.Body | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host
    
    # 4. Deletar mensagem da fila (simulando processamento bem-sucedido)
    Write-Host "`n4. Deletando mensagem (processamento concluído)..." -ForegroundColor Yellow
    
    aws sqs delete-message `
        --queue-url $queueUrl `
        --receipt-handle $message.ReceiptHandle `
        --endpoint-url $ENDPOINT `
        --region $REGION
    
    Write-Host "✅ Mensagem deletada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Nenhuma mensagem na fila" -ForegroundColor Yellow
}

# 5. Verificar fila novamente
Write-Host "`n5. Verificando fila após processamento..." -ForegroundColor Yellow

$finalAttributes = aws sqs get-queue-attributes `
    --queue-url $queueUrl `
    --attribute-names ApproximateNumberOfMessages `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Mensagens restantes: $($finalAttributes.Attributes.ApproximateNumberOfMessages)" -ForegroundColor Green

Write-Host "`n✅ Testes concluídos!" -ForegroundColor Green
