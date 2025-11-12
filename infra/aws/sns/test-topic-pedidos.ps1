# Script de teste para o tópico SNS de pedidos
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$TOPIC_NAME = "PedidosConcluidos"

Write-Host "=== Testando Tópico SNS: $TOPIC_NAME ===" -ForegroundColor Cyan

# Obter ARN do tópico
Write-Host "`nObtendo ARN do tópico..." -ForegroundColor Yellow

$topics = aws sns list-topics `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$topicArn = ($topics.Topics | Where-Object { $_.TopicArn -like "*$TOPIC_NAME*" }).TopicArn

if ($topicArn) {
    Write-Host "✅ Tópico encontrado!" -ForegroundColor Green
    Write-Host "   ARN: $topicArn" -ForegroundColor Gray
} else {
    Write-Host "❌ Tópico não encontrado!" -ForegroundColor Red
    exit 1
}

# 1. Publicar mensagem simples
Write-Host "`n1. Publicando mensagem simples..." -ForegroundColor Yellow

$pedidoId = "pedido-" + (Get-Date -Format "yyyyMMddHHmmss")

$result1 = aws sns publish `
    --topic-arn $topicArn `
    --subject "Pedido Pronto!" `
    --message "Novo pedido concluído: $pedidoId" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Mensagem publicada!" -ForegroundColor Green
Write-Host "   Message ID: $($result1.MessageId)" -ForegroundColor Gray
Write-Host "   Subject: Pedido Pronto!" -ForegroundColor Gray
Write-Host "   Message: Novo pedido concluído: $pedidoId" -ForegroundColor Gray

# 2. Publicar mensagem estruturada (JSON)
Write-Host "`n2. Publicando mensagem estruturada (JSON)..." -ForegroundColor Yellow

$messageBody = @{
    "TopicArn" = $topicArn
    "Message" = "Novo pedido concluído: $pedidoId"
    "Subject" = "Pedido Pronto!"
    "Detalhes" = @{
        "pedidoId" = $pedidoId
        "cliente" = "João Silva"
        "mesa" = 5
        "total" = 43.00
        "status" = "concluido"
        "timestamp" = (Get-Date).ToString("o")
    }
} | ConvertTo-Json -Depth 10 -Compress

$tempFile = New-TemporaryFile
[System.IO.File]::WriteAllText($tempFile.FullName, $messageBody)

$result2 = aws sns publish `
    --topic-arn $topicArn `
    --subject "Pedido Concluído - Detalhes" `
    --message "file://$($tempFile.FullName)" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Remove-Item $tempFile

Write-Host "✅ Mensagem estruturada publicada!" -ForegroundColor Green
Write-Host "   Message ID: $($result2.MessageId)" -ForegroundColor Gray

# 3. Publicar com atributos de mensagem
Write-Host "`n3. Publicando mensagem com atributos..." -ForegroundColor Yellow

$result3 = aws sns publish `
    --topic-arn $topicArn `
    --subject "Pedido Express!" `
    --message "Pedido $pedidoId está pronto para retirada!" `
    --message-attributes '{\"tipo\":{\"DataType\":\"String\",\"StringValue\":\"express\"},\"prioridade\":{\"DataType\":\"Number\",\"StringValue\":\"1\"}}' `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Mensagem com atributos publicada!" -ForegroundColor Green
Write-Host "   Message ID: $($result3.MessageId)" -ForegroundColor Gray
Write-Host "   Atributos: tipo=express, prioridade=1" -ForegroundColor Gray

# 4. Listar subscrições do tópico
Write-Host "`n4. Listando subscrições do tópico..." -ForegroundColor Yellow

$subscriptions = aws sns list-subscriptions-by-topic `
    --topic-arn $topicArn `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Subscrições encontradas: $($subscriptions.Subscriptions.Count)" -ForegroundColor Green
foreach ($sub in $subscriptions.Subscriptions) {
    Write-Host "   - Protocol: $($sub.Protocol), Endpoint: $($sub.Endpoint)" -ForegroundColor Gray
}

# 5. Verificar atributos do tópico
Write-Host "`n5. Verificando atributos do tópico..." -ForegroundColor Yellow

$attributes = aws sns get-topic-attributes `
    --topic-arn $topicArn `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Atributos do tópico:" -ForegroundColor Green
Write-Host "   Subscrições confirmadas: $($attributes.Attributes.SubscriptionsConfirmed)" -ForegroundColor Gray
Write-Host "   Subscrições pendentes: $($attributes.Attributes.SubscriptionsPending)" -ForegroundColor Gray
Write-Host "   Subscrições deletadas: $($attributes.Attributes.SubscriptionsDeleted)" -ForegroundColor Gray

Write-Host "`n✅ Testes concluídos!" -ForegroundColor Green
Write-Host "`nOperações testadas:" -ForegroundColor Cyan
Write-Host "  ✅ Publicação de mensagem simples" -ForegroundColor White
Write-Host "  ✅ Publicação de mensagem estruturada (JSON)" -ForegroundColor White
Write-Host "  ✅ Publicação com atributos de mensagem" -ForegroundColor White
Write-Host "  ✅ Listagem de subscrições" -ForegroundColor White
Write-Host "  ✅ Verificação de atributos do tópico" -ForegroundColor White
Write-Host "`nTotal de mensagens publicadas: 3" -ForegroundColor Cyan
