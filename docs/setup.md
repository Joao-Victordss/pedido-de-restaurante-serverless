# 🚀 Guia de Setup - Sistema de Pedidos Serverless

Este guia ajudará você a configurar e executar o sistema completo de pedidos usando CloudFormation.

## 📋 Pré-requisitos

### Obrigatórios
- **Docker Desktop** (versão 20.10+)
- **AWS CLI v2** (versão 2.0+)
- **PowerShell** (versão 5.1+ no Windows) ou **Bash** (Linux/Mac)
- **Python 3.11+** (para o frontend)

### Verificar Dependências

```bash
make doctor
```

Isso verificará se todas as ferramentas necessárias estão instaladas.

## 🏁 Quick Start (5 minutos)

### 1. Clonar o Repositório

```bash
git clone https://github.com/Joao-Victordss/pedido-de-restaurante-serverless.git
cd pedido-de-restaurante-serverless
```

### 2. Subir LocalStack

```bash
make up
```

Aguarde ~30 segundos até o LocalStack ficar pronto.

### 3. Deploy da Stack CloudFormation

```bash
make deploy
```

Esse comando irá:
- 📦 Empacotar as 3 Lambdas com dependências
- 🚀 Criar/atualizar a stack CloudFormation
- ✅ Provisionar 26 recursos AWS:
  - DynamoDB (tabela Pedidos)
  - SQS (3 filas: pedidos-queue, pedidos-queue-dlq, notificacoes-frontend)
  - S3 (2 buckets: pedidos-comprovantes, lambda-deployments)
  - SNS (1 tópico com 3 subscriptions)
  - Lambda (3 funções: criar-pedido, processar-pedido, listar-pedidos)
  - API Gateway (REST API com 3 endpoints)
  - IAM (3 roles com políticas específicas)
  - Event Source Mapping (SQS → processar-pedido)

### 4. Verificar Status

```bash
make status
```

Você deve ver: `pedidos-serverless-stack    UPDATE_COMPLETE` ou `CREATE_COMPLETE`

### 5. Testar API

```bash
make test-api
```

Deve retornar `201` (pedido criado com sucesso).

### 6. Acessar Frontend

```bash
cd frontend
python proxy.py
```

Abra http://localhost:8080 no navegador.

## 📖 Comandos Disponíveis

### Gerenciamento do LocalStack

```bash
make up          # Subir LocalStack
make down        # Parar LocalStack (mantém dados)
make clean       # Parar e remover volumes (limpa tudo)
make logs        # Ver logs do container
make ps          # Ver status do container
```

### Gerenciamento da Stack

```bash
make deploy      # Deploy/atualizar stack CloudFormation
make destroy     # Destruir stack (requer confirmação "DELETAR")
make status      # Ver status da stack
```

### Testes

```bash
make test-api    # Testar endpoints da API
make doctor      # Verificar dependências do sistema
```

### Frontend

```bash
cd frontend
python proxy.py  # Iniciar proxy (porta 8080)
```

## 🏗️ Arquitetura da Stack

### Recursos Criados

A stack CloudFormation provisiona automaticamente:

#### 1. DynamoDB
- **Tabela:** `Pedidos`
- **Chave:** `id` (String)
- **Billing:** PAY_PER_REQUEST
- **Atributos:** id, cliente, mesa, itens, status, total, comprovante_s3, created_at, updated_at

#### 2. SQS (3 filas)
- **pedidos-queue**: Fila principal para processamento assíncrono
  - Visibility Timeout: 60s
  - Retention: 4 dias
  - Max Receives: 3 (depois vai para DLQ)
- **pedidos-queue-dlq**: Dead Letter Queue para mensagens com falha
- **notificacoes-frontend**: Fila para notificações em tempo real no frontend (SNS fan-out)

#### 3. S3 (2 buckets)
- **pedidos-comprovantes**: Armazena PDFs de comprovantes
  - Versioning habilitado
  - Lifecycle: expira após 90 dias
- **lambda-deployments**: Armazena pacotes ZIP das Lambdas

#### 4. SNS
- **Tópico:** `PedidosConcluidos`
- **Subscriptions:**
  - Email: cozinha@restaurante.com (confirmação pendente)
  - HTTP: http://localhost:3000/webhook
  - SQS: notificacoes-frontend (para frontend consumir)

#### 5. Lambda (3 funções)
- **criar-pedido**: Cria pedidos, salva no DynamoDB, envia para SQS
  - Runtime: Python 3.9
  - Memory: 128 MB
  - Timeout: 30s
- **processar-pedido**: Processa SQS, gera PDF, atualiza DynamoDB, publica SNS
  - Runtime: Python 3.9
  - Memory: 256 MB
  - Timeout: 60s
  - Dependências: fpdf2, fontTools, Pillow, defusedxml
- **listar-pedidos**: Lista todos os pedidos com ordenação
  - Runtime: Python 3.9
  - Memory: 128 MB
  - Timeout: 30s

#### 6. API Gateway
- **Tipo:** REST API
- **Nome:** `pedidos-api`
- **Stage:** `dev`
- **Endpoints:**
  - `POST /pedidos` → criar-pedido Lambda
  - `GET /pedidos` → listar-pedidos Lambda
  - `OPTIONS /pedidos` → CORS mock response
- **CORS:** Habilitado para todos os endpoints

#### 7. IAM
- **CriarPedidoLambdaRole**: Permite DynamoDB PutItem, S3 GetObject, SQS SendMessage
- **ProcessarPedidoLambdaRole**: Permite SQS (receive/delete), DynamoDB (scan/update), SNS Publish, S3 PutObject
- **ListarPedidosLambdaRole**: Permite DynamoDB Scan

#### 8. Event Source Mapping
- Conecta `pedidos-queue` → `processar-pedido` Lambda
- Batch Size: 10 mensagens
- Processa automaticamente mensagens da fila

## 🔄 Fluxo End-to-End

```
1. Cliente (Frontend/API) → POST /pedidos
                              ↓
2. API Gateway → criar-pedido Lambda
                              ↓
3. DynamoDB ← salva pedido (status: pendente)
   SQS ← envia mensagem para processar
                              ↓
4. processar-pedido Lambda ← consome SQS (Event Source Mapping)
                              ↓
5. Gera PDF comprovante (fpdf2) → S3
   Atualiza DynamoDB (status: processado)
   Publica notificação → SNS
                              ↓
6. SNS Fan-out:
   - Email para cozinha@restaurante.com
   - HTTP webhook para localhost:3000
   - SQS notificacoes-frontend (para frontend consumir)
                              ↓
7. Frontend consulta:
   - GET /pedidos → listar-pedidos Lambda
   - Polling SQS notificacoes-frontend para atualizações em tempo real
```

## 🧪 Testando o Sistema

### 1. Teste Manual via curl

```bash
# Criar pedido
curl -X POST "http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente": "João Silva",
    "mesa": 5,
    "itens": [
      {"nome": "Pizza", "quantidade": 1, "preco": 30.0}
    ],
    "total": 30.0
  }'

# Listar pedidos
curl "http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos"
```

### 2. Verificar Recursos AWS

```bash
# Ver pedidos no DynamoDB
aws dynamodb scan --table-name Pedidos \
  --endpoint-url http://localhost:4566 --region us-east-1

# Ver mensagens na fila SQS
aws sqs receive-message \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/pedidos-queue \
  --endpoint-url http://localhost:4566 --region us-east-1

# Ver PDFs no S3
aws s3 ls s3://pedidos-comprovantes/ \
  --endpoint-url http://localhost:4566 --region us-east-1

# Ver notificações no SQS frontend
aws sqs receive-message \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/notificacoes-frontend \
  --endpoint-url http://localhost:4566 --region us-east-1
```

### 3. Ver Logs das Lambdas

```bash
# Logs da Lambda criar-pedido
aws logs tail /aws/lambda/criar-pedido --region us-east-1 \
  --endpoint-url http://localhost:4566 --follow

# Logs da Lambda processar-pedido
aws logs tail /aws/lambda/processar-pedido --region us-east-1 \
  --endpoint-url http://localhost:4566 --follow

# Logs da Lambda listar-pedidos
aws logs tail /aws/lambda/listar-pedidos --region us-east-1 \
  --endpoint-url http://localhost:4566 --follow
```

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
pedido-de-restaurante-serverless/
├── infra/
│   ├── cloudformation/
│   │   ├── stack.yaml              # Template CloudFormation (26 recursos)
│   │   ├── deploy.ps1              # Script de deploy (packaging + upload)
│   │   ├── destroy.ps1             # Script de destruição (com confirmação)
│   │   └── README.md               # Documentação CloudFormation
│   └── docker-compose.yml          # LocalStack container
├── src/
│   └── lambdas/
│       ├── criar-pedido/           # Lambda POST /pedidos
│       │   └── index.py
│       ├── processar-pedido/       # Lambda worker SQS
│       │   ├── index.py
│       │   └── requirements.txt    # fpdf2>=2.7.0
│       └── listar-pedidos/         # Lambda GET /pedidos
│           └── index.py
├── frontend/
│   ├── proxy.py                    # Proxy Python (porta 8080)
│   ├── index.html                  # UI do sistema
│   └── styles.css
├── Makefile                        # Comandos make
└── README.md
```

### Modificar Lambdas

1. Edite o código em `src/lambdas/{nome-lambda}/index.py`
2. Se adicionar dependências, crie/atualize `requirements.txt`
3. Faça redeploy:
   ```bash
   make deploy
   ```

O script de deploy automaticamente:
- Detecta mudanças no código
- Instala dependências Python (exceto boto3 - já no runtime)
- Empacota tudo em ZIP
- Faz upload para S3
- Atualiza as Lambdas

### Modificar Infraestrutura

1. Edite `infra/cloudformation/stack.yaml`
2. Faça redeploy:
   ```bash
   make deploy
   ```

CloudFormation detectará mudanças e atualizará apenas os recursos modificados.

## 🐛 Troubleshooting

### LocalStack não inicia

```bash
# Ver logs
make logs

# Reiniciar
make clean
make up
```

### Stack falha ao criar

```bash
# Ver eventos da stack
aws cloudformation describe-stack-events \
  --stack-name pedidos-serverless-stack \
  --endpoint-url http://localhost:4566 --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Destruir e recriar
make destroy
make deploy
```

### Lambda com erro de importação

Verifique se as dependências estão no ZIP:

```bash
cd infra/cloudformation
aws s3 cp s3://lambda-deployments/processar-pedido.zip . \
  --endpoint-url http://localhost:4566 --region us-east-1
Expand-Archive -Path processar-pedido.zip -DestinationPath temp
Get-ChildItem temp
```

### API retorna 404

```bash
# Verificar API ID
aws apigateway get-rest-apis \
  --endpoint-url http://localhost:4566 --region us-east-1 \
  --query 'items[?name==`pedidos-api`].[id,name]'

# Verificar deployment
aws apigateway get-deployments \
  --rest-api-id {API_ID} \
  --endpoint-url http://localhost:4566 --region us-east-1
```

### Pedidos não são processados

```bash
# Verificar mensagens na DLQ
aws sqs receive-message \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/pedidos-queue-dlq \
  --endpoint-url http://localhost:4566 --region us-east-1

# Ver logs da Lambda processar-pedido
aws logs tail /aws/lambda/processar-pedido --region us-east-1 \
  --endpoint-url http://localhost:4566 --follow
```

## 📊 Monitoramento

### Ver Status Geral

```bash
make status

# Ou detalhado:
aws cloudformation describe-stacks \
  --stack-name pedidos-serverless-stack \
  --endpoint-url http://localhost:4566 --region us-east-1
```

### Ver Todos os Recursos

```bash
aws cloudformation list-stack-resources \
  --stack-name pedidos-serverless-stack \
  --endpoint-url http://localhost:4566 --region us-east-1
```

### Ver Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name pedidos-serverless-stack \
  --endpoint-url http://localhost:4566 --region us-east-1 \
  --query 'Stacks[0].Outputs'
```

## 🧹 Limpeza

### Destruir Stack (mantém LocalStack)

```bash
make destroy
```

Você precisará digitar `DELETAR` para confirmar. Isso remove:
- Todos os 26 recursos da stack
- Dados no DynamoDB
- Arquivos no S3
- Mensagens nas filas

### Parar LocalStack

```bash
make down    # Mantém volumes
make clean   # Remove volumes também
```

## 🚀 Próximos Passos

1. **Explorar o frontend**: http://localhost:8080
2. **Testar fluxo completo**: Criar pedido → aguardar processamento → verificar notificação
3. **Monitorar logs**: Ver Lambdas processando em tempo real
4. **Modificar código**: Experimentar mudanças nas Lambdas
5. **Explorar CloudFormation**: Ver template em `infra/cloudformation/stack.yaml`

## 📚 Documentação Adicional

- [CloudFormation README](../infra/cloudformation/README.md) - Detalhes da stack
- [API Documentation](api.md) - Endpoints e schemas
- [Architecture](architecture.md) - Visão geral da arquitetura

## 🤝 Suporte

Para issues ou dúvidas:
- Consulte o [Troubleshooting](#-troubleshooting)
- Verifique logs com `make logs`
- Execute `make doctor` para verificar dependências

---

**Desenvolvido com ❤️ usando AWS Serverless, CloudFormation e LocalStack**
