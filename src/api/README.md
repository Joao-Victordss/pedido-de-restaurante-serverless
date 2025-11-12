# API REST - Pedidos de Restaurante# API Gateway - Configuração



API REST para gerenciar pedidos de restaurante, construída com AWS API Gateway e Lambda Functions.Este diretório contém a configuração do API Gateway.



## 📋 Visão Geral## Estrutura



A API expõe endpoints HTTP para criar e consultar pedidos. Quando um pedido é criado, ele é automaticamente processado em background, gerando um comprovante em PDF.```

src/api/

### Fluxo de Processamento├── openapi.yaml           # Especificação OpenAPI 3.0

├── authorizer.py          # Lambda Authorizer (opcional)

```└── README.md

POST /pedidos```

    ↓

Lambda criar-pedido## OpenAPI Specification

    ↓

DynamoDB (status: pendente) + SQSO arquivo `openapi.yaml` define todos os endpoints da API:

    ↓

Lambda processar-pedido (trigger SQS)- `POST /pedidos` - Criar pedido

    ↓- `GET /pedidos` - Listar pedidos

Gera PDF → S3 + Atualiza DynamoDB (status: processado) + Publica SNS- `GET /pedidos/{pedidoId}` - Consultar pedido

```- `PATCH /pedidos/{pedidoId}/status` - Atualizar status



## 🚀 Endpoints## Deploy Local (LocalStack)



### Base URL (LocalStack)### 1. Criar API Gateway

```

http://localhost:4566/restapis/{API_ID}/prod/_user_request_```powershell

```# Criar API REST

$apiId = aws --endpoint-url=http://localhost:4566 `

---  apigateway create-rest-api `

  --name "pedidos-api" `

### POST /pedidos  --region us-east-1 `

  --query 'id' `

Cria um novo pedido.  --output text



**Request:**Write-Host "API ID: $apiId"

```http```

POST /pedidos

Content-Type: application/json### 2. Criar recursos e métodos



{```powershell

  "cliente": "João Silva",# Get root resource

  "mesa": 10,$rootId = aws --endpoint-url=http://localhost:4566 `

  "itens": ["Pizza", "Refrigerante", "Sobremesa"]  apigateway get-resources `

}  --rest-api-id $apiId `

```  --region us-east-1 `

  --query 'items[0].id' `

**Validações:**  --output text

- `cliente`: string, mínimo 3 caracteres (obrigatório)

- `mesa`: número inteiro, maior que 0 (obrigatório)# Criar recurso /pedidos

- `itens`: array não vazio de strings (obrigatório)$resourceId = aws --endpoint-url=http://localhost:4566 `

  apigateway create-resource `

**Response (201 Created):**  --rest-api-id $apiId `

```json  --parent-id $rootId `

{  --path-part "pedidos" `

  "message": "Pedido criado com sucesso",  --region us-east-1 `

  "pedidoId": "pedido-20251112145045",  --query 'id' `

  "status": "pendente",  --output text

  "timestamp": "2025-11-12T14:50:45.363518"

}# Criar método POST

```aws --endpoint-url=http://localhost:4566 `

  apigateway put-method `

**Erros:**  --rest-api-id $apiId `

- `400 Bad Request`: Dados inválidos  --resource-id $resourceId `

- `500 Internal Server Error`: Erro no servidor  --http-method POST `

  --authorization-type NONE `

---  --region us-east-1



### GET /pedidos# Integração com Lambda

$lambdaArn = "arn:aws:lambda:us-east-1:000000000000:function:criar-pedido"

Lista todos os pedidos com suporte a paginação e filtros.$uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$lambdaArn/invocations"



**Query Parameters:**aws --endpoint-url=http://localhost:4566 `

- `limit` (opcional): Número máximo de resultados (padrão: 10, máximo: 100)  apigateway put-integration `

- `lastKey` (opcional): ID do último item da página anterior (para paginação)  --rest-api-id $apiId `

- `status` (opcional): Filtrar por status (`pendente`, `processado`, `erro`)  --resource-id $resourceId `

  --http-method POST `

**Exemplos:**  --type AWS_PROXY `

  --integration-http-method POST `

```http  --uri $uri `

# Listar primeiros 5 pedidos  --region us-east-1

GET /pedidos?limit=5```



# Listar pedidos processados### 3. Deploy da API

GET /pedidos?status=processado&limit=10

```powershell

# Próxima página# Criar deployment

GET /pedidos?limit=5&lastKey=pedido-20251112145045aws --endpoint-url=http://localhost:4566 `

```  apigateway create-deployment `

  --rest-api-id $apiId `

**Response (200 OK):**  --stage-name local `

```json  --region us-east-1

{

  "pedidos": [# URL da API

    {$apiUrl = "http://localhost:4566/restapis/$apiId/local/_user_request_"

      "id": "pedido-20251112145045",Write-Host "API URL: $apiUrl"

      "cliente": "Maria Santos",```

      "mesa": 15,

      "status": "processado",### 4. Testar API

      "timestamp": "2025-11-12T14:50:45.363518",

      "itens": ["Hamburguer", "Batata Frita", "Coca Cola"],```powershell

      "comprovante_url": "comprovantes/pedido-20251112145045.pdf",# Criar pedido

      "updated_at": "2025-11-12T14:50:56.875538"curl -X POST "$apiUrl/pedidos" `

    },  -H "Content-Type: application/json" `

    {  -d '{"cliente":"João Silva","itens":["Pizza"],"mesa":5}'

      "id": "pedido-20251112142348",```

      "cliente": "João Silva",

      "mesa": 5,## Deploy Produção (AWS)

      "status": "processado",

      "timestamp": "2025-11-12T14:23:48.591037",### 1. Usar OpenAPI Specification

      "itens": ["Pizza", "Refrigerante"],

      "comprovante_url": "comprovantes/pedido-20251112142348.pdf",```powershell

      "updated_at": "2025-11-12T14:24:31.780524"# Deploy usando OpenAPI

    }aws apigateway import-rest-api `

  ],  --body file://openapi.yaml `

  "count": 2,  --region us-east-1

  "lastKey": "pedido-20251112142348"```

}

```### 2. Deploy com Terraform



**Campos opcionais no pedido:**```hcl

- `comprovante_url`: Disponível apenas após processamento# main.tf

- `updated_at`: Disponível apenas após processamento ou atualizaçãoresource "aws_api_gateway_rest_api" "pedidos_api" {

  name        = "pedidos-api"

---  description = "API de pedidos do restaurante"



### GET /pedidos/{id}  body = file("${path.module}/openapi.yaml")

}

Busca um pedido específico por ID.

resource "aws_api_gateway_deployment" "production" {

**Request:**  rest_api_id = aws_api_gateway_rest_api.pedidos_api.id

```http  stage_name  = "production"

GET /pedidos/pedido-20251112145045

```  depends_on = [aws_api_gateway_rest_api.pedidos_api]

}

**Response (200 OK):**

```jsonoutput "api_url" {

{  value = aws_api_gateway_deployment.production.invoke_url

  "id": "pedido-20251112145045",}

  "cliente": "Maria Santos",```

  "mesa": 15,

  "status": "processado",### 3. Deploy com AWS SAM

  "timestamp": "2025-11-12T14:50:45.363518",

  "itens": ["Hamburguer", "Batata Frita", "Coca Cola"],```yaml

  "comprovante_url": "comprovantes/pedido-20251112145045.pdf",# template.yaml

  "updated_at": "2025-11-12T14:50:56.875538"Resources:

}  PedidosApi:

```    Type: AWS::Serverless::Api

    Properties:

**Erros:**      Name: pedidos-api

- `404 Not Found`: Pedido não encontrado      StageName: production

- `500 Internal Server Error`: Erro no servidor      DefinitionBody:

        Fn::Transform:

---          Name: AWS::Include

          Parameters:

## 📊 Status dos Pedidos            Location: openapi.yaml

```

| Status | Descrição |

|--------|-----------|## Configurações Avançadas

| `pendente` | Pedido criado, aguardando processamento |

| `processado` | Pedido processado com sucesso, PDF gerado |### 1. Throttling

| `erro` | Erro durante o processamento |

```yaml

---x-amazon-apigateway-request-validators:

  all:

## 🔒 CORS    validateRequestBody: true

    validateRequestParameters: true

A API está configurada com CORS permissivo para desenvolvimento:

x-amazon-apigateway-throttle:

```  rateLimit: 1000

Access-Control-Allow-Origin: *  burstLimit: 2000

Access-Control-Allow-Headers: Content-Type```

Access-Control-Allow-Methods: GET, POST, OPTIONS

```### 2. CORS



---```yaml

paths:

## 🛠️ Arquitetura  /pedidos:

    options:

### Componentes AWS      responses:

        '200':

1. **API Gateway REST**          headers:

   - 3 endpoints HTTP            Access-Control-Allow-Origin:

   - Integração proxy com Lambda              schema:

   - Stage: `prod`                type: string

            Access-Control-Allow-Methods:

2. **Lambda Functions**              schema:

   - `criar-pedido`: Cria e valida pedidos                type: string

   - `listar-pedidos`: Lista e busca pedidos            Access-Control-Allow-Headers:

   - `processar-pedido`: Processa pedidos em background (trigger SQS)              schema:

                type: string

3. **DynamoDB**```

   - Tabela: `Pedidos`

   - Chave primária: `id` (String)### 3. API Keys

   - Billing: Pay-per-request

```powershell

4. **SQS**# Criar API Key

   - Queue: `pedidos-queue`$keyId = aws apigateway create-api-key `

   - DLQ: `pedidos-queue-dlq`  --name "pedidos-api-key" `

   - Trigger para Lambda `processar-pedido`  --enabled `

  --query 'id' `

5. **S3**  --output text

   - Bucket: `pedidos-comprovantes`

   - Armazena PDFs dos comprovantes# Criar Usage Plan

$planId = aws apigateway create-usage-plan `

6. **SNS**  --name "pedidos-plan" `

   - Topic: `PedidosConcluidos`  --throttle rateLimit=100,burstLimit=200 `

   - Notifica quando pedidos são processados  --quota limit=10000,period=MONTH `

  --query 'id' `

---  --output text



## 📦 Deploy (LocalStack)# Associar API Key ao Usage Plan

aws apigateway create-usage-plan-key `

### Pré-requisitos  --usage-plan-id $planId `

- Docker (LocalStack rodando)  --key-id $keyId `

- AWS CLI configurado  --key-type API_KEY

- PowerShell```



### Deploy completo### 4. Lambda Authorizer



```powershell```python

# Deploy de toda infraestrutura + Lambdas + API Gateway# authorizer.py

.\infra\localstack\scripts\deploy-all.ps1def handler(event, context):

```    """Custom Lambda Authorizer."""

    token = event['authorizationToken']

### Deploy individual    

    # Validar token (ex: JWT)

```powershell    if validate_token(token):

# Apenas infraestrutura AWS        return generate_policy('user', 'Allow', event['methodArn'])

.\infra\aws\deploy-all.ps1    else:

        return generate_policy('user', 'Deny', event['methodArn'])

# Apenas Lambda criar-pedido

.\infra\localstack\scripts\deploy-lambda-criar-pedido.ps1def generate_policy(principal_id, effect, resource):

    return {

# Apenas Lambda processar-pedido        'principalId': principal_id,

.\infra\localstack\scripts\deploy-lambda-processar-pedido.ps1        'policyDocument': {

            'Version': '2012-10-17',

# Apenas Lambda listar-pedidos            'Statement': [{

.\infra\localstack\scripts\deploy-lambda-listar-pedidos.ps1                'Action': 'execute-api:Invoke',

                'Effect': effect,

# Apenas API Gateway                'Resource': resource

.\infra\localstack\scripts\deploy-apigateway.ps1            }]

```        }

    }

---```



## 🧪 Testes## Monitoramento



### Testar API completa### CloudWatch Logs



```powershell```powershell

# Testa todos os endpoints do API Gateway# Habilitar logs

.\infra\localstack\scripts\test-apigateway.ps1aws apigateway update-stage `

```  --rest-api-id $apiId `

  --stage-name production `

### Testar Lambdas individualmente  --patch-operations "op=replace,path=/*/logging/loglevel,value=INFO"



```powershell# Ver logs

# Testar Lambda criar-pedidoaws logs tail /aws/apigateway/$apiId --follow

.\infra\localstack\scripts\test-lambda-criar-pedido.ps1```



# Testar Lambda processar-pedido### Métricas

.\infra\localstack\scripts\test-lambda-processar-pedido.ps1

- **4XXError**: Erros do cliente

# Testar Lambda listar-pedidos- **5XXError**: Erros do servidor

.\infra\localstack\scripts\test-lambda-listar-pedidos.ps1- **Count**: Total de requisições

```- **Latency**: Latência das requisições

- **IntegrationLatency**: Latência da integração com Lambda

### Exemplos com curl

```powershell

```bash# Consultar métricas

# Criar pedidoaws cloudwatch get-metric-statistics `

curl -X POST http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos \  --namespace AWS/ApiGateway `

  -H "Content-Type: application/json" \  --metric-name Count `

  -d '{"cliente":"João Silva","mesa":10,"itens":["Pizza","Refrigerante"]}'  --dimensions Name=ApiName,Value=pedidos-api `

  --start-time 2025-01-01T00:00:00Z `

# Listar pedidos  --end-time 2025-01-02T00:00:00Z `

curl http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos?limit=5  --period 3600 `

  --statistics Sum

# Buscar pedido específico```

curl http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos/pedido-20251112145045

## Testes

# Filtrar por status

curl http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos?status=processado```bash

```# Testes de integração

pytest tests/integration/test_api.py

---

# Testes de carga

## 📝 Logsartillery run tests/load/api-load-test.yaml

```

### Ver logs das Lambdas

## Documentação

```powershell

# Logs da Lambda criar-pedidoA documentação interativa da API está disponível em:

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/criar-pedido --region us-east-1 --follow- Swagger UI: `/docs`

- ReDoc: `/redoc`

# Logs da Lambda processar-pedido

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/processar-pedido --region us-east-1 --follow## Próximos Passos



# Logs da Lambda listar-pedidos1. ⏳ Criar openapi.yaml completo

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/listar-pedidos --region us-east-1 --follow2. ⏳ Implementar authorizer.py (opcional)

```3. ⏳ Configurar CORS

4. ⏳ Configurar throttling

---5. ⏳ Deploy em LocalStack

6. ⏳ Testes end-to-end

## 🐛 Troubleshooting

### API retorna 404
- Verifique se o API ID está correto
- Confirme que o stage `prod` foi deployado
- Use o formato correto da URL: `/restapis/{API_ID}/prod/_user_request_/pedidos`

### Pedido não é processado automaticamente
- Verifique se a Lambda `processar-pedido` está deployada
- Confirme se o SQS trigger está configurado
- Verifique os logs da Lambda para erros

### Erro 500 ao listar pedidos
- Pode haver pedidos com campos faltando no DynamoDB
- A Lambda `listar-pedidos` trata campos opcionais, mas verifique os logs

### PDF não é gerado
- Verifique se o bucket S3 existe
- Confirme se a Lambda `processar-pedido` tem permissões (LocalStack é permissivo)
- Veja os logs da Lambda para detalhes do erro

---

## 📚 Referências

- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [AWS Lambda](https://docs.aws.amazon.com/lambda/)
- [LocalStack](https://docs.localstack.cloud/)
- [fpdf2 - PDF Generation](https://py-pdf.github.io/fpdf2/)

---

## 🔄 Atualizações Futuras

- [ ] Autenticação e autorização (API Key / JWT)
- [ ] Rate limiting
- [ ] Validação de schemas com API Gateway Request Validator
- [ ] WebSocket para notificações em tempo real
- [ ] Cache com ElastiCache
- [ ] Métricas e dashboards com CloudWatch
