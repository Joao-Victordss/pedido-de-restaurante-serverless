# 🍽️ Sistema de Pedidos de Restaurante - Serverless# 🍽️ Sistema de Pedidos de Restaurante - Serverless# Pedido Restaurante



Sistema serverless completo para gerenciamento de pedidos de restaurante, utilizando **AWS Lambda**, **DynamoDB**, **SQS**, **S3**, **SNS** e **API Gateway**.



# 🍽️ Sistema de Pedidos de Restaurante - Serverless

Sistema completo de gerenciamento de pedidos de restaurante com arquitetura **serverless** em **AWS**, rodando localmente com **LocalStack** e infraestrutura definida em **CloudFormation**.

Tecnologias principais:
- **AWS Lambda** (3 funções: criar, processar, listar pedidos)
- **API Gateway REST** (3 endpoints públicos)
- **DynamoDB**, **SQS** (com DLQ), **S3**, **SNS**
- **CloudFormation** para IaC
- **Docker + LocalStack** para ambiente local
- **Frontend** em HTML/CSS/JS com proxy Python

---

## 📋 Visão Geral da Arquitetura

Fluxo principal do sistema em ambiente local (via LocalStack):

1. **Cliente / Frontend** envia `POST /pedidos` para o API Gateway.
2. **API Gateway (`pedidos-api`)** integra via proxy com a Lambda `criar-pedido`.
3. **Lambda criar-pedido** valida o payload, grava o pedido na tabela **DynamoDB `Pedidos`** com status `pendente` e envia mensagem para a fila **SQS `pedidos-queue`**.
4. **Lambda processar-pedido** é disparada por Event Source Mapping da fila SQS, gera o **PDF de comprovante** usando `fpdf2`, salva no bucket **S3 `pedidos-comprovantes`**, atualiza o pedido no DynamoDB para `processado` e publica evento no tópico **SNS `PedidosConcluidos`**.
5. **SNS** faz fan-out para integrações (email, HTTP webhook e fila SQS de notificações para o frontend).
6. **Lambda listar-pedidos** é exposta em `GET /pedidos` para listagem com ordenação/paginação.

Todos os recursos são criados e gerenciados via **CloudFormation** (`infra/cloudformation/stack.yaml`) executando em LocalStack.

---

## 🚀 Quick Start

### ✅ Pré-requisitos

- **Docker Desktop** (20.10+)
- **AWS CLI v2**
- **PowerShell 5.1+** (Windows) ou **Bash** (Linux/Mac)
- **Python 3.11+** (para rodar o proxy/frontend)

Verifique as dependências com:

```bash
make doctor
```

### 1. Clonar o repositório

```bash
git clone https://github.com/Joao-Victordss/pedido-de-restaurante-serverless.git
cd pedido-de-restaurante-serverless
```

### 2. Subir o LocalStack

```bash
make up
```

O comando usa `infra/docker-compose.yml`. Aguarde ~30s até o LocalStack ficar pronto.

### 3. Deploy da stack CloudFormation

```bash
make deploy
```

Esse comando executa `infra/cloudformation/deploy.ps1` e irá:
- Empacotar as 3 Lambdas com dependências (usando o bucket de deployments)
- Criar/atualizar a stack `pedidos-serverless-stack` no LocalStack
- Provisionar DynamoDB, SQS (fila + DLQ + fila de notificações), S3, SNS, API Gateway, IAM e Event Source Mapping

### 4. Ver status da stack

```bash
make status
```

Saída esperada: `CREATE_COMPLETE` ou `UPDATE_COMPLETE`.

### 5. Testar a API

```bash
make test-api
```

O comando descobre o `API_ID` automaticamente no LocalStack e envia um `POST /pedidos`. A resposta HTTP deve ser `201`.

### 6. Subir o frontend

```bash
cd frontend
python proxy.py
```

Acesse no navegador:
- `http://localhost:8080` (frontend + proxy detectando automaticamente o API ID)

---

## 📁 Estrutura do Projeto

```text
pedido-de-restaurante-serverless/
├── docs/
│   ├── api.md                 # Documentação detalhada da API REST
│   └── setup.md               # Guia de setup completo (CloudFormation + LocalStack)
├── infra/
│   ├── cloudformation/
│   │   ├── stack.yaml         # Template CloudFormation (infra completa)
│   │   ├── deploy.ps1         # Deploy/atualização da stack
│   │   └── destroy.ps1        # Destruição da stack
│   └── docker-compose.yml     # LocalStack + dependências
├── src/
│   └── lambdas/
│       ├── criar-pedido/
│       │   └── index.py       # Lambda POST /pedidos
│       ├── processar-pedido/
│       │   ├── index.py       # Lambda worker (SQS → PDF → S3 → SNS)
│       │   └── requirements.txt
│       └── listar-pedidos/
│           └── index.py       # Lambda GET /pedidos
├── frontend/
│   ├── index.html             # UI web do sistema
│   ├── styles.css             # Estilos
│   ├── script.js              # Lógica de consumo da API
│   ├── proxy.py               # Proxy HTTP que resolve o API ID no LocalStack
│   └── start.ps1              # Script para subir proxy+frontend
├── Makefile                   # Comandos make (up, down, deploy, status, etc.)
└── README.md                  # Este arquivo
```

Para detalhes adicionais de setup, veja `docs/setup.md`.

---

## 🌐 API REST

A API REST é exposta pelo API Gateway criado via CloudFormation com o nome `pedidos-api` e stage `dev`.

### Endpoints principais

> A URL base segue o formato do LocalStack:  
> `http://localhost:4566/restapis/{API_ID}/dev/_user_request_`

| Método | Caminho        | Descrição                            |
|--------|----------------|--------------------------------------|
| POST   | `/pedidos`     | Cria um novo pedido                  |
| GET    | `/pedidos`     | Lista pedidos (com ordenação)        |

#### Exemplo: criar pedido

```bash
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
```

#### Exemplo: listar pedidos

```bash
curl "http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos"
```

Mais exemplos de payloads e schemas estão em `docs/api.md`.

---

## ⚙️ Lambdas

- `src/lambdas/criar-pedido/index.py`
  - Trigger: API Gateway `POST /pedidos`
  - Ações: valida payload, grava em DynamoDB, envia mensagem para SQS.

- `src/lambdas/processar-pedido/index.py`
  - Trigger: Event Source Mapping da fila SQS `pedidos-queue`.
  - Ações: lê mensagem, gera PDF com `fpdf2`, salva no bucket S3, atualiza pedido no DynamoDB, publica no SNS.
  - Dependências declaradas em `requirements.txt` (empacotadas no deploy).

- `src/lambdas/listar-pedidos/index.py`
  - Trigger: API Gateway `GET /pedidos`.
  - Ações: lê pedidos do DynamoDB e retorna JSON ordenado.

---

## 🛠️ Comandos Make

Principais comandos definidos no `Makefile`:

```bash
make up        # Subir LocalStack (docker compose up)
make down      # Parar LocalStack
make logs      # Ver logs do LocalStack
make ps        # Ver status dos containers
make deploy    # Deploy/atualização da stack CloudFormation
make destroy   # Destruir stack CloudFormation
make status    # Ver status da stack
make test-api  # Testar rapidamente o endpoint POST /pedidos
make doctor    # Verificar dependências locais
make clean     # Parar LocalStack e remover volumes
```

---

## 🔧 Observações de Ambiente

- Tudo roda em **LocalStack** (Docker) apontando para `http://localhost:4566`.
- Região padrão: `us-east-1`.
- Credenciais: qualquer par (LocalStack não valida, apenas exige presença).
- Outputs úteis da stack (via `make status` / `aws cloudformation describe-stacks`):
  - Nome da tabela DynamoDB (`Pedidos`), URLs das filas SQS, nome/ARN do bucket S3 de comprovantes, ARN do tópico SNS.

Para um passo-a-passo mais detalhado (incluindo comandos AWS CLI para inspecionar recursos), consulte `docs/setup.md`.

---

## 🧪 Testes e Observabilidade

Alguns comandos úteis (todos usando LocalStack):

```bash
# Ver itens da tabela DynamoDB
aws dynamodb scan \
  --table-name Pedidos \
  --endpoint-url http://localhost:4566 \
  --region us-east-1

# Ver arquivos de comprovantes no S3
aws s3 ls s3://pedidos-comprovantes/ \
  --endpoint-url http://localhost:4566 \
  --region us-east-1

# Ler mensagens da fila DLQ
aws sqs receive-message \
  --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/pedidos-queue-dlq \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

Logs das Lambdas são expostos via CloudWatch emulado pelo LocalStack e podem ser consultados conforme descrito em `docs/setup.md`.

---

## 📚 Documentação Relacionada

- `docs/setup.md` – guia de setup completo (recomendado ler se for rodar localmente).
- `docs/api.md` – especificação detalhada dos endpoints, payloads e respostas.
- `infra/cloudformation/README.md` – detalhes da stack e comparação com scripts manuais.
- `frontend/README.md` – como usar o frontend e o proxy.

---

## 📄 Licença e Contribuição

Este repositório é um **projeto educacional** para estudo de arquitetura serverless com AWS, CloudFormation e LocalStack.

Sinta‑se à vontade para abrir issues, sugerir melhorias ou enviar PRs com novas features (ex.: autenticação, métricas, WebSocket, CI/CD).

---

**Desenvolvido com ❤️ usando AWS Serverless, CloudFormation, LocalStack e um frontend simples em HTML/JS.**

## 👥 Contribuindo

Este é um projeto de aprendizado. Sinta-se livre para explorar e modificar!

---

**Desenvolvido com ❤️ usando AWS Serverless e LocalStack**
