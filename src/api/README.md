# API Gateway - Configuração

Este diretório contém a configuração do API Gateway.

## Estrutura

```
src/api/
├── openapi.yaml           # Especificação OpenAPI 3.0
├── authorizer.py          # Lambda Authorizer (opcional)
└── README.md
```

## OpenAPI Specification

O arquivo `openapi.yaml` define todos os endpoints da API:

- `POST /pedidos` - Criar pedido
- `GET /pedidos` - Listar pedidos
- `GET /pedidos/{pedidoId}` - Consultar pedido
- `PATCH /pedidos/{pedidoId}/status` - Atualizar status

## Deploy Local (LocalStack)

### 1. Criar API Gateway

```powershell
# Criar API REST
$apiId = aws --endpoint-url=http://localhost:4566 `
  apigateway create-rest-api `
  --name "pedidos-api" `
  --region us-east-1 `
  --query 'id' `
  --output text

Write-Host "API ID: $apiId"
```

### 2. Criar recursos e métodos

```powershell
# Get root resource
$rootId = aws --endpoint-url=http://localhost:4566 `
  apigateway get-resources `
  --rest-api-id $apiId `
  --region us-east-1 `
  --query 'items[0].id' `
  --output text

# Criar recurso /pedidos
$resourceId = aws --endpoint-url=http://localhost:4566 `
  apigateway create-resource `
  --rest-api-id $apiId `
  --parent-id $rootId `
  --path-part "pedidos" `
  --region us-east-1 `
  --query 'id' `
  --output text

# Criar método POST
aws --endpoint-url=http://localhost:4566 `
  apigateway put-method `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --authorization-type NONE `
  --region us-east-1

# Integração com Lambda
$lambdaArn = "arn:aws:lambda:us-east-1:000000000000:function:criar-pedido"
$uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$lambdaArn/invocations"

aws --endpoint-url=http://localhost:4566 `
  apigateway put-integration `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --type AWS_PROXY `
  --integration-http-method POST `
  --uri $uri `
  --region us-east-1
```

### 3. Deploy da API

```powershell
# Criar deployment
aws --endpoint-url=http://localhost:4566 `
  apigateway create-deployment `
  --rest-api-id $apiId `
  --stage-name local `
  --region us-east-1

# URL da API
$apiUrl = "http://localhost:4566/restapis/$apiId/local/_user_request_"
Write-Host "API URL: $apiUrl"
```

### 4. Testar API

```powershell
# Criar pedido
curl -X POST "$apiUrl/pedidos" `
  -H "Content-Type: application/json" `
  -d '{"cliente":"João Silva","itens":["Pizza"],"mesa":5}'
```

## Deploy Produção (AWS)

### 1. Usar OpenAPI Specification

```powershell
# Deploy usando OpenAPI
aws apigateway import-rest-api `
  --body file://openapi.yaml `
  --region us-east-1
```

### 2. Deploy com Terraform

```hcl
# main.tf
resource "aws_api_gateway_rest_api" "pedidos_api" {
  name        = "pedidos-api"
  description = "API de pedidos do restaurante"

  body = file("${path.module}/openapi.yaml")
}

resource "aws_api_gateway_deployment" "production" {
  rest_api_id = aws_api_gateway_rest_api.pedidos_api.id
  stage_name  = "production"

  depends_on = [aws_api_gateway_rest_api.pedidos_api]
}

output "api_url" {
  value = aws_api_gateway_deployment.production.invoke_url
}
```

### 3. Deploy com AWS SAM

```yaml
# template.yaml
Resources:
  PedidosApi:
    Type: AWS::Serverless::Api
    Properties:
      Name: pedidos-api
      StageName: production
      DefinitionBody:
        Fn::Transform:
          Name: AWS::Include
          Parameters:
            Location: openapi.yaml
```

## Configurações Avançadas

### 1. Throttling

```yaml
x-amazon-apigateway-request-validators:
  all:
    validateRequestBody: true
    validateRequestParameters: true

x-amazon-apigateway-throttle:
  rateLimit: 1000
  burstLimit: 2000
```

### 2. CORS

```yaml
paths:
  /pedidos:
    options:
      responses:
        '200':
          headers:
            Access-Control-Allow-Origin:
              schema:
                type: string
            Access-Control-Allow-Methods:
              schema:
                type: string
            Access-Control-Allow-Headers:
              schema:
                type: string
```

### 3. API Keys

```powershell
# Criar API Key
$keyId = aws apigateway create-api-key `
  --name "pedidos-api-key" `
  --enabled `
  --query 'id' `
  --output text

# Criar Usage Plan
$planId = aws apigateway create-usage-plan `
  --name "pedidos-plan" `
  --throttle rateLimit=100,burstLimit=200 `
  --quota limit=10000,period=MONTH `
  --query 'id' `
  --output text

# Associar API Key ao Usage Plan
aws apigateway create-usage-plan-key `
  --usage-plan-id $planId `
  --key-id $keyId `
  --key-type API_KEY
```

### 4. Lambda Authorizer

```python
# authorizer.py
def handler(event, context):
    """Custom Lambda Authorizer."""
    token = event['authorizationToken']
    
    # Validar token (ex: JWT)
    if validate_token(token):
        return generate_policy('user', 'Allow', event['methodArn'])
    else:
        return generate_policy('user', 'Deny', event['methodArn'])

def generate_policy(principal_id, effect, resource):
    return {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource': resource
            }]
        }
    }
```

## Monitoramento

### CloudWatch Logs

```powershell
# Habilitar logs
aws apigateway update-stage `
  --rest-api-id $apiId `
  --stage-name production `
  --patch-operations "op=replace,path=/*/logging/loglevel,value=INFO"

# Ver logs
aws logs tail /aws/apigateway/$apiId --follow
```

### Métricas

- **4XXError**: Erros do cliente
- **5XXError**: Erros do servidor
- **Count**: Total de requisições
- **Latency**: Latência das requisições
- **IntegrationLatency**: Latência da integração com Lambda

```powershell
# Consultar métricas
aws cloudwatch get-metric-statistics `
  --namespace AWS/ApiGateway `
  --metric-name Count `
  --dimensions Name=ApiName,Value=pedidos-api `
  --start-time 2025-01-01T00:00:00Z `
  --end-time 2025-01-02T00:00:00Z `
  --period 3600 `
  --statistics Sum
```

## Testes

```bash
# Testes de integração
pytest tests/integration/test_api.py

# Testes de carga
artillery run tests/load/api-load-test.yaml
```

## Documentação

A documentação interativa da API está disponível em:
- Swagger UI: `/docs`
- ReDoc: `/redoc`

## Próximos Passos

1. ⏳ Criar openapi.yaml completo
2. ⏳ Implementar authorizer.py (opcional)
3. ⏳ Configurar CORS
4. ⏳ Configurar throttling
5. ⏳ Deploy em LocalStack
6. ⏳ Testes end-to-end
