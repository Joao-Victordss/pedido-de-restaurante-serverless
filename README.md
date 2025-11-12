# 🍽️ Sistema de Pedidos de Restaurante - Serverless# Pedido Restaurante



Sistema serverless para gerenciamento de pedidos de restaurante, utilizando AWS Lambda, DynamoDB, SQS, S3 e SNS.## Ambiente local com LocalStack



## 📋 Visão GeralPré-requisitos: Docker, AWS CLI, jq.



Este projeto implementa um sistema completo de gerenciamento de pedidos com arquitetura serverless:Passos:

1. Copie variáveis de ambiente:

```   ```bash

API Gateway → Lambda Criar Pedido → DynamoDB + SQS   cp infra/.env.example infra/.env

                                         ↓   ```

                            Lambda Processar Pedido → S3 + SNS

```Suba o LocalStack e aguarde o healthcheck:



### Fluxo de Operação```

make up

1. **Cliente faz pedido** via API Gateway (POST /pedidos)```

2. **Lambda Criar Pedido** salva no DynamoDB e envia para SQS

3. **Lambda Processar Pedido** consome SQS, gera PDF e salva no S3Bootstrap de recursos básicos:

4. **SNS notifica** cozinha e sistema via email/webhook

```

## 📁 Estrutura do Projetomake bootstrap

```

```

pedido-de-restaurante-serverless/Ver logs:

├── docs/                          # Documentação

│   ├── architecture.md            # Arquitetura do sistema```

│   ├── setup.md                   # Guia de instalaçãomake logs

│   └── api.md                     # Documentação da API```

│

├── infra/                         # InfraestruturaLimpar recursos e encerrar:

│   ├── localstack/                # Scripts LocalStack

│   │   ├── bootstrap.sh           # Provisionar recursos```

│   │   ├── teardown.sh            # Remover recursosmake teardown

│   │   └── wait-for-localstack.sh # Health checkmake down

│   │```

│   ├── aws/                       # Recursos AWS

│   │   ├── deploy-all.ps1         # Deploy de todos os recursosEndpoints: http://localhost:4566

│   │   ├── deploy-all.sh

│   │   ├── dynamodb/              # Tabela PedidosRegião: us-east-1

│   │   ├── sqs/                   # Fila de pedidos

│   │   ├── s3/                    # Bucket de comprovantesCredenciais: definidas em infra/.env (fakes para uso local).

│   │   └── sns/                   # Tópico de notificações

│   │---

│   └── docker-compose.yml         # LocalStack container

│## Como o Copilot deve atuar

├── src/                           # Código-fonte- Abra cada arquivo no caminho indicado e cole o conteúdo.

│   ├── lambdas/                   # Funções Lambda- O Copilot completa pequenos ajustes e comentários se você escrever cabeçalhos como “// TODO: criar recursos app na Issue 3+”.

│   │   ├── criar-pedido/          # Lambda de criação- Use as tasks do VS Code: Ctrl+Shift+P > Run Task > “LocalStack: Up” > “LocalStack: Bootstrap”.

│   │   └── processar-pedido/      # Lambda de processamento

│   │## Teste rápido

│   ├── shared/                    # Código compartilhadoDepois de `make bootstrap`:

│   │   ├── validators.py          # Validações```

│   │   ├── constants.py           # Constantes# Ver arquivo de teste no S3

│   │   ├── pdf_generator.py      # Geração de PDFsaws --endpoint-url http://localhost:4566 s3 ls s3://health-check-bucket/

│   │   └── aws_clients.py         # Clientes AWS

│   │# Ler mensagens da fila

│   └── api/                       # API Gatewayaws --endpoint-url http://localhost:4566 sqs receive-message \

│       └── openapi.yaml           # Especificação OpenAPI  --queue-url "$(aws --endpoint-url http://localhost:4566 sqs get-queue-url --queue-name health-check-queue --query 'QueueUrl' --output text)"

│```

├── tests/                         # Testes
│   ├── unit/                      # Testes unitários
│   └── integration/               # Testes de integração
│
├── Makefile                       # Comandos make
└── README.md                      # Este arquivo
```

## 🚀 Quick Start

### Pré-requisitos

- Docker Desktop
- AWS CLI v2
- jq (JSON processor)
- PowerShell 5.1+ (Windows) ou Bash (Linux/Mac)

### 1. Subir LocalStack

```bash
make up
```

Aguarde o container ficar "healthy" (cerca de 30 segundos).

### 2. Provisionar Recursos AWS

**Opção 1: Deploy completo**
```powershell
.\infra\aws\deploy-all.ps1
```

**Opção 2: Deploy individual**
```powershell
.\infra\aws\dynamodb\create-table-pedidos.ps1
.\infra\aws\sqs\create-queue-pedidos.ps1
.\infra\aws\s3\create-bucket-comprovantes.ps1
.\infra\aws\sns\create-topic-pedidos.ps1
```

### 3. Testar Recursos

```powershell
# Testar DynamoDB
.\infra\aws\dynamodb\test-table-pedidos.ps1

# Testar SQS
.\infra\aws\sqs\test-queue-pedidos.ps1

# Testar S3
.\infra\aws\s3\test-bucket-comprovantes.ps1

# Testar SNS
.\infra\aws\sns\test-topic-pedidos.ps1
```

## 📚 Documentação

- **[Setup Completo](docs/setup.md)** - Guia detalhado de instalação
- **[Arquitetura](docs/architecture.md)** - Descrição da arquitetura do sistema
- **[API](docs/api.md)** - Documentação dos endpoints

### Documentação por Componente

- [Lambdas](src/lambdas/README.md) - Funções Lambda
- [Shared](src/shared/README.md) - Código compartilhado
- [API Gateway](src/api/README.md) - Configuração da API
- [DynamoDB](infra/aws/dynamodb/README.md) - Tabela de pedidos
- [SQS](infra/aws/sqs/README.md) - Fila de processamento
- [S3](infra/aws/s3/README.md) - Armazenamento de PDFs
- [SNS](infra/aws/sns/README.md) - Sistema de notificações

## 🛠️ Comandos Make

```bash
make up          # Subir LocalStack
make down        # Parar LocalStack
make logs        # Ver logs do container
make bootstrap   # Provisionar recursos
make teardown    # Remover recursos
make doctor      # Verificar saúde do sistema
```

## 🔧 Configuração

### LocalStack

- **Endpoint:** http://localhost:4566
- **Região:** us-east-1
- **Credenciais:** test/test (fake para desenvolvimento local)

### Variáveis de Ambiente

Copie o arquivo de exemplo e ajuste conforme necessário:

```bash
cp infra/.env.example infra/.env
```

## 🧪 Testes

### Testes Unitários

```bash
cd src/lambdas/criar-pedido
pytest tests/unit/
```

### Testes de Integração

```bash
pytest tests/integration/
```

### Testes Manuais

Os scripts de teste em cada componente permitem testar manualmente:

```powershell
.\infra\aws\dynamodb\test-table-pedidos.ps1
.\infra\aws\sqs\test-queue-pedidos.ps1
.\infra\aws\s3\test-bucket-comprovantes.ps1
.\infra\aws\sns\test-topic-pedidos.ps1
```

## 📊 Recursos AWS

### DynamoDB - Tabela Pedidos

- **Nome:** Pedidos
- **Chave Primária:** id (String)
- **Billing:** Pay-Per-Request
- **Atributos:** cliente, itens, mesa, status, timestamp

### SQS - Fila de Pedidos

- **Nome:** pedidos-queue
- **DLQ:** pedidos-queue-dlq
- **Visibility Timeout:** 30 segundos
- **Retention:** 4 dias
- **Max Receives:** 3

### S3 - Bucket de Comprovantes

- **Nome:** pedidos-comprovantes
- **Versioning:** Habilitado
- **Lifecycle:** Expiração após 90 dias

### SNS - Tópico de Notificações

- **Nome:** PedidosConcluidos
- **Subscriptions:** Email (cozinha) + HTTP (webhook)

## 🚧 Status do Projeto

- ✅ DynamoDB configurado e testado
- ✅ SQS configurado e testado (com DLQ)
- ✅ S3 configurado e testado (com lifecycle)
- ✅ SNS configurado e testado (2 subscriptions)
- ✅ Estrutura de projeto organizada
- ✅ Documentação completa
- ⏳ Lambda Criar Pedido (próxima etapa)
- ⏳ Lambda Processar Pedido (próxima etapa)
- ⏳ API Gateway (próxima etapa)
- ⏳ Testes end-to-end (próxima etapa)

## 🐛 Troubleshooting

### LocalStack não inicia

```bash
# Verificar logs
make logs

# Reiniciar container
make down
make up
```

### AWS CLI retorna erros

```bash
# Verificar se LocalStack está rodando
docker ps | grep localstack

# Testar conectividade
aws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1
```

### Recursos não foram criados

```bash
# Re-executar bootstrap
make teardown
make bootstrap
```

Para mais detalhes, consulte [docs/setup.md](docs/setup.md#troubleshooting).

## 📝 Próximos Passos

1. **Implementar Lambda Criar Pedido**
   - Criar `src/lambdas/criar-pedido/index.py`
   - Validar entrada
   - Salvar no DynamoDB
   - Enviar para SQS

2. **Implementar Lambda Processar Pedido**
   - Criar `src/lambdas/processar-pedido/index.py`
   - Consumir SQS
   - Gerar PDF do comprovante
   - Upload no S3
   - Publicar notificação SNS

3. **Configurar API Gateway**
   - Criar OpenAPI spec
   - Integrar com Lambda Criar Pedido
   - Configurar CORS
   - Implementar autenticação

4. **Testes End-to-End**
   - Criar pedido via API
   - Verificar processamento
   - Validar PDF no S3
   - Confirmar notificação SNS

## 📄 Licença

Este projeto é um exemplo educacional de arquitetura serverless.

## 👥 Contribuindo

Este é um projeto de aprendizado. Sinta-se livre para explorar e modificar!
