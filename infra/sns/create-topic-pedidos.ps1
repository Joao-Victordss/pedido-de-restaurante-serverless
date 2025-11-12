# Script para criar tópico SNS para notificações de pedidos no LocalStack
$ErrorActionPreference = "Stop"

$ENDPOINT = "http://localhost:4566"
$REGION = "us-east-1"
$TOPIC_NAME = "PedidosConcluidos"

Write-Host "=== Criando Tópico SNS: $TOPIC_NAME ===" -ForegroundColor Cyan

# Criar o tópico SNS
Write-Host "`nCriando tópico..." -ForegroundColor Yellow

$result = aws sns create-topic `
    --name $TOPIC_NAME `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$topicArn = $result.TopicArn
Write-Host "✅ Tópico criado com sucesso!" -ForegroundColor Green
Write-Host "   ARN: $topicArn" -ForegroundColor Gray

# Configurar atributos do tópico
Write-Host "`nConfigurando atributos do tópico..." -ForegroundColor Yellow

aws sns set-topic-attributes `
    --topic-arn $topicArn `
    --attribute-name DisplayName `
    --attribute-value "Notificacoes de Pedidos Concluidos" `
    --endpoint-url $ENDPOINT `
    --region $REGION

Write-Host "✅ Display Name configurado!" -ForegroundColor Green

# Obter atributos do tópico
Write-Host "`nObtendo atributos do tópico..." -ForegroundColor Yellow

$attributes = aws sns get-topic-attributes `
    --topic-arn $topicArn `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Atributos do tópico:" -ForegroundColor Green
Write-Host "   Topic ARN: $($attributes.Attributes.TopicArn)" -ForegroundColor Gray
Write-Host "   Display Name: $($attributes.Attributes.DisplayName)" -ForegroundColor Gray
Write-Host "   Owner: $($attributes.Attributes.Owner)" -ForegroundColor Gray

# Criar uma subscrição de teste via email (simulado no LocalStack)
Write-Host "`nCriando subscrição de teste (email)..." -ForegroundColor Yellow

$subscriptionResult = aws sns subscribe `
    --topic-arn $topicArn `
    --protocol email `
    --notification-endpoint "cozinha@restaurante.com" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

$subscriptionArn = $subscriptionResult.SubscriptionArn
Write-Host "✅ Subscrição criada!" -ForegroundColor Green
Write-Host "   Subscription ARN: $subscriptionArn" -ForegroundColor Gray
Write-Host "   Endpoint: cozinha@restaurante.com" -ForegroundColor Gray
Write-Host "   Protocol: email" -ForegroundColor Gray

# Criar subscrição HTTP para webhook (útil para testes)
Write-Host "`nCriando subscrição HTTP..." -ForegroundColor Yellow

$httpSubscription = aws sns subscribe `
    --topic-arn $topicArn `
    --protocol http `
    --notification-endpoint "http://localhost:3000/webhook/pedidos" `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Subscrição HTTP criada!" -ForegroundColor Green
Write-Host "   Subscription ARN: $($httpSubscription.SubscriptionArn)" -ForegroundColor Gray
Write-Host "   Endpoint: http://localhost:3000/webhook/pedidos" -ForegroundColor Gray

# Listar todas as subscrições
Write-Host "`nListando subscrições..." -ForegroundColor Yellow

$subscriptions = aws sns list-subscriptions-by-topic `
    --topic-arn $topicArn `
    --endpoint-url $ENDPOINT `
    --region $REGION `
    --output json | ConvertFrom-Json

Write-Host "✅ Total de subscrições: $($subscriptions.Subscriptions.Count)" -ForegroundColor Green

Write-Host "`n✅ Configuração completa!" -ForegroundColor Green
Write-Host "`nResumo:" -ForegroundColor Cyan
Write-Host "  Topic Name: $TOPIC_NAME" -ForegroundColor White
Write-Host "  Topic ARN: $topicArn" -ForegroundColor White
Write-Host "  Subscrições:" -ForegroundColor White
Write-Host "    - Email: cozinha@restaurante.com" -ForegroundColor Gray
Write-Host "    - HTTP: http://localhost:3000/webhook/pedidos" -ForegroundColor Gray
