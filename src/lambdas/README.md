# Lambdas - Sistema de Pedidos

Este diretório contém as funções Lambda do sistema.

## Estrutura

```
src/lambdas/
├── criar-pedido/          # Lambda de criação de pedidos (POST /pedidos)
│   ├── index.py
│   ├── README.md
│   └── requirements.txt   # se necessário
├── processar-pedido/      # Lambda de processamento assíncrono (SQS → PDF → S3 → SNS)
│   ├── index.py
│   ├── README.md
│   └── requirements.txt   # fpdf2 e outras libs de PDF
└── listar-pedidos/        # Lambda de listagem de pedidos (GET /pedidos)
  ├── index.py
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

**Ambiente (CloudFormation / LocalStack):**
- `DYNAMODB_TABLE`: Nome da tabela DynamoDB (`Pedidos`)
- `SQS_QUEUE_URL`: URL da fila SQS principal (`pedidos-queue`)

**Payload esperado (corpo HTTP POST /pedidos):**
```json
{
  "cliente": "João Silva",
  "mesa": 5,
  "itens": [
    { "nome": "Pizza", "quantidade": 1, "preco": 30.0 }
  ],
  "total": 30.0
}
```

---

### 2. processar-pedido

**Trigger:** SQS (pedidos-queue)

**Função:**
- Consome mensagens da fila
- Gera PDF do comprovante
- Upload do PDF no S3
- Atualiza status no DynamoDB
- Publica notificação no SNS

**Ambiente (CloudFormation / LocalStack):**
- `DYNAMODB_TABLE`: Nome da tabela DynamoDB (`Pedidos`)
- `S3_BUCKET`: Nome do bucket S3 de comprovantes (`pedidos-comprovantes`)
- `SNS_TOPIC_ARN`: ARN do tópico SNS (`PedidosConcluidos`)

**Dependências:**
- `boto3` (já presente no runtime da Lambda)
- `fpdf2` (definida em `processar-pedido/requirements.txt`)

---

### 3. listar-pedidos

**Trigger:** API Gateway (GET /pedidos)

**Função:**
- Lê pedidos da tabela DynamoDB `Pedidos`
- Permite filtro por `status`
- Implementa paginação via `limit` e `lastKey`
- Retorna JSON com lista de pedidos e metadados de paginação

**Ambiente:**
- `DYNAMODB_TABLE`: Nome da tabela DynamoDB (`Pedidos`)

**Exemplo de resposta:**
```json
{
  "pedidos": [
    {
      "id": "pedido-20251111120000",
      "cliente": "João Silva",
      "mesa": 5,
      "status": "processado",
      "timestamp": "2025-11-11T12:00:00Z"
    }
  ],
  "count": 1,
  "lastKey": "pedido-20251111120000"
}
```

## Deploy Local (LocalStack)

Hoje o deploy das Lambdas é feito **integrado à stack CloudFormation**, via `infra/cloudformation/deploy.ps1`, acionado por:

```bash
make deploy
```

CloudFormation empacota o código, faz upload para o bucket de deployments e atualiza as três funções (`criar-pedido`, `processar-pedido`, `listar-pedidos`).

Para detalhes do processo de deploy, ver `infra/cloudformation/README.md` e `docs/setup.md`.

## Logs e Monitoramento

### LocalStack

```powershell
# Ver logs da Lambda
aws --endpoint-url=http://localhost:4566 `
  logs tail /aws/lambda/criar-pedido `
  --region us-east-1 `
  --follow
```

### AWS real

Esta base é focada em **desenvolvimento local com LocalStack**. Para deploy em conta AWS real, recomenda-se criar um template específico (CloudFormation/SAM/Terraform) reaproveitando o código das Lambdas, mas isso está **fora do escopo atual** do repositório.
