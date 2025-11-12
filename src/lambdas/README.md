# Lambdas - Sistema de Pedidos

Este diretório contém as funções Lambda do sistema.

## Estrutura

```
src/lambdas/
├── criar-pedido/          # Lambda de criação de pedidos
│   ├── index.py
│   ├── requirements.txt
│   └── README.md
└── processar-pedido/      # Lambda de processamento de pedidos
    ├── index.py
    ├── requirements.txt
    └── README.md
```

## Lambdas

### 1. criar-pedido

**Trigger:** API Gateway (POST /pedidos)

**Função:**
- Valida dados de entrada
- Cria pedido no DynamoDB
- Envia mensagem para SQS
- Retorna resposta HTTP

**Ambiente:**
- `DYNAMODB_TABLE`: Nome da tabela DynamoDB
- `SQS_QUEUE_URL`: URL da fila SQS

**Dependências:**
- boto3

---

### 2. processar-pedido

**Trigger:** SQS (pedidos-queue)

**Função:**
- Consome mensagens da fila
- Gera PDF do comprovante
- Upload do PDF no S3
- Atualiza status no DynamoDB
- Publica notificação no SNS

**Ambiente:**
- `DYNAMODB_TABLE`: Nome da tabela DynamoDB
- `S3_BUCKET`: Nome do bucket S3
- `SNS_TOPIC_ARN`: ARN do tópico SNS

**Dependências:**
- boto3
- reportlab (geração de PDF)

## Deploy Local (LocalStack)

### 1. Criar pacote da Lambda

```powershell
# Criar diretório de build
cd src/lambdas/criar-pedido
mkdir build
pip install -r requirements.txt -t build/
cp index.py build/

# Criar ZIP
cd build
Compress-Archive -Path * -DestinationPath ../criar-pedido.zip
```

### 2. Criar função Lambda

```powershell
aws --endpoint-url=http://localhost:4566 `
  lambda create-function `
  --function-name criar-pedido `
  --runtime python3.11 `
  --role arn:aws:iam::000000000000:role/lambda-role `
  --handler index.handler `
  --zip-file fileb://criar-pedido.zip `
  --region us-east-1 `
  --environment Variables="{DYNAMODB_TABLE=Pedidos,SQS_QUEUE_URL=http://localhost:4566/000000000000/pedidos-queue}"
```

### 3. Testar Lambda

```powershell
# Criar evento de teste
$event = @{
  body = '{"cliente":"João Silva","itens":["Pizza"],"mesa":5}'
} | ConvertTo-Json

# Invocar Lambda
aws --endpoint-url=http://localhost:4566 `
  lambda invoke `
  --function-name criar-pedido `
  --payload $event `
  response.json `
  --region us-east-1

# Ver resposta
Get-Content response.json | ConvertFrom-Json
```

## Deploy Produção (AWS)

### 1. Criar role IAM

```bash
aws iam create-role \
  --role-name lambda-pedidos-role \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name lambda-pedidos-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

### 2. Criar políticas customizadas

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/Pedidos"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:us-east-1:*:pedidos-queue"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::pedidos-comprovantes/*"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:us-east-1:*:PedidosConcluidos"
    }
  ]
}
```

### 3. Deploy com AWS SAM

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  CriarPedidoFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: criar-pedido
      Handler: index.handler
      Runtime: python3.11
      CodeUri: src/lambdas/criar-pedido/
      Environment:
        Variables:
          DYNAMODB_TABLE: Pedidos
          SQS_QUEUE_URL: !GetAtt PedidosQueue.QueueUrl
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /pedidos
            Method: post
```

```bash
sam build
sam deploy --guided
```

## Logs e Monitoramento

### LocalStack

```powershell
# Ver logs da Lambda
aws --endpoint-url=http://localhost:4566 `
  logs tail /aws/lambda/criar-pedido `
  --region us-east-1 `
  --follow
```

### AWS

```bash
# CloudWatch Logs
aws logs tail /aws/lambda/criar-pedido --follow

# Métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=criar-pedido \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

## Testes

```bash
# Testes unitários
cd src/lambdas/criar-pedido
pytest tests/unit/

# Testes de integração
pytest tests/integration/
```

## Próximos Passos

1. ⏳ Implementar `criar-pedido/index.py`
2. ⏳ Implementar `processar-pedido/index.py`
3. ⏳ Criar testes unitários
4. ⏳ Criar testes de integração
5. ⏳ Configurar CI/CD
