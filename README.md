# 🍽️ Sistema de Pedidos de Restaurante - Serverless# 🍽️ Sistema de Pedidos de Restaurante - Serverless# Pedido Restaurante



Sistema serverless completo para gerenciamento de pedidos de restaurante, utilizando **AWS Lambda**, **DynamoDB**, **SQS**, **S3**, **SNS** e **API Gateway**.



## 📋 Visão GeralSistema serverless para gerenciamento de pedidos de restaurante, utilizando AWS Lambda, DynamoDB, SQS, S3 e SNS.## Ambiente local com LocalStack



Este projeto implementa um sistema de pedidos com arquitetura event-driven totalmente serverless:



```## 📋 Visão GeralPré-requisitos: Docker, AWS CLI, jq.

Cliente (HTTP)

    ↓

API Gateway REST

    ↓Este projeto implementa um sistema completo de gerenciamento de pedidos com arquitetura serverless:Passos:

Lambda criar-pedido → DynamoDB (status: pendente) + SQS

                           ↓1. Copie variáveis de ambiente:

                   Lambda processar-pedido (trigger SQS)

                           ↓```   ```bash

                   Gera PDF → S3 + Atualiza DynamoDB (status: processado) + SNS

```API Gateway → Lambda Criar Pedido → DynamoDB + SQS   cp infra/.env.example infra/.env



### Features Implementadas                                         ↓   ```



✅ **API REST completa** com 3 endpoints                              Lambda Processar Pedido → S3 + SNS

✅ **Criação de pedidos** com validação  

✅ **Processamento assíncrono** via SQS  ```Suba o LocalStack e aguarde o healthcheck:

✅ **Geração automática de PDFs** com fpdf2  

✅ **Armazenamento em S3** com lifecycle  

✅ **Notificações SNS** para integração  

✅ **Listagem e consulta** de pedidos com paginação  ### Fluxo de Operação```

✅ **Deploy automatizado** com scripts PowerShell  

make up

## 🚀 Quick Start

1. **Cliente faz pedido** via API Gateway (POST /pedidos)```

### Pré-requisitos

2. **Lambda Criar Pedido** salva no DynamoDB e envia para SQS

- **Docker Desktop** (LocalStack)

- **AWS CLI v2**3. **Lambda Processar Pedido** consome SQS, gera PDF e salva no S3Bootstrap de recursos básicos:

- **Python 3.11+**

- **PowerShell 5.1+**4. **SNS notifica** cozinha e sistema via email/webhook



### 1. Iniciar LocalStack```



```bash## 📁 Estrutura do Projetomake bootstrap

make up

``````



Aguarde o container ficar "healthy" (~30 segundos).```



### 2. Deploy Completopedido-de-restaurante-serverless/Ver logs:



```powershell├── docs/                          # Documentação

# Deploy de tudo: infraestrutura + Lambdas + API Gateway

.\infra\localstack\scripts\deploy-all.ps1│   ├── architecture.md            # Arquitetura do sistema```

```

│   ├── setup.md                   # Guia de instalaçãomake logs

Esse comando irá:

1. Provisionar recursos AWS (DynamoDB, SQS, S3, SNS)│   └── api.md                     # Documentação da API```

2. Fazer deploy das 3 Lambdas (criar, processar, listar)

3. Configurar API Gateway REST com 3 endpoints│

4. Validar todo o ambiente

├── infra/                         # InfraestruturaLimpar recursos e encerrar:

### 3. Testar API

│   ├── localstack/                # Scripts LocalStack

```powershell

# Testa todos os endpoints HTTP│   │   ├── bootstrap.sh           # Provisionar recursos```

.\infra\localstack\scripts\test-apigateway.ps1

```│   │   ├── teardown.sh            # Remover recursosmake teardown



**Pronto!** 🎉 A API está funcionando em:│   │   └── wait-for-localstack.sh # Health checkmake down

```

http://localhost:4566/restapis/{API_ID}/prod/_user_request_│   │```

```

│   ├── aws/                       # Recursos AWS

## 📁 Estrutura do Projeto

│   │   ├── deploy-all.ps1         # Deploy de todos os recursosEndpoints: http://localhost:4566

```

pedido-de-restaurante-serverless/│   │   ├── deploy-all.sh

├── src/

│   ├── lambdas/│   │   ├── dynamodb/              # Tabela PedidosRegião: us-east-1

│   │   ├── criar-pedido/          # ✅ Lambda POST /pedidos

│   │   ├── processar-pedido/      # ✅ Lambda worker (SQS trigger)│   │   ├── sqs/                   # Fila de pedidos

│   │   └── listar-pedidos/        # ✅ Lambda GET /pedidos

│   └── api/│   │   ├── s3/                    # Bucket de comprovantesCredenciais: definidas em infra/.env (fakes para uso local).

│       └── README.md              # ✅ Documentação da API REST

││   │   └── sns/                   # Tópico de notificações

├── infra/

│   ├── localstack/│   │---

│   │   └── scripts/

│   │       ├── deploy-all.ps1              # ✅ Deploy completo│   └── docker-compose.yml         # LocalStack container

│   │       ├── deploy-apigateway.ps1       # Deploy API Gateway

│   │       ├── deploy-lambda-*.ps1         # Deploy Lambdas individuais│## Como o Copilot deve atuar

│   │       ├── test-apigateway.ps1         # Teste API completa

│   │       └── test-lambda-*.ps1           # Testes unitários├── src/                           # Código-fonte- Abra cada arquivo no caminho indicado e cole o conteúdo.

│   │

│   ├── aws/│   ├── lambdas/                   # Funções Lambda- O Copilot completa pequenos ajustes e comentários se você escrever cabeçalhos como “// TODO: criar recursos app na Issue 3+”.

│   │   ├── deploy-all.ps1                  # Provisiona recursos AWS

│   │   ├── dynamodb/                       # Tabela Pedidos│   │   ├── criar-pedido/          # Lambda de criação- Use as tasks do VS Code: Ctrl+Shift+P > Run Task > “LocalStack: Up” > “LocalStack: Bootstrap”.

│   │   ├── sqs/                            # Fila pedidos-queue

│   │   ├── s3/                             # Bucket comprovantes│   │   └── processar-pedido/      # Lambda de processamento

│   │   └── sns/                            # Tópico notificações

│   ││   │## Teste rápido

│   └── docker-compose.yml          # LocalStack container

││   ├── shared/                    # Código compartilhadoDepois de `make bootstrap`:

├── Makefile                        # Comandos make (up, down, logs, etc)

└── README.md                       # Este arquivo│   │   ├── validators.py          # Validações```

```

│   │   ├── constants.py           # Constantes# Ver arquivo de teste no S3

## 🌐 API REST Endpoints

│   │   ├── pdf_generator.py      # Geração de PDFsaws --endpoint-url http://localhost:4566 s3 ls s3://health-check-bucket/

| Método | Endpoint | Descrição |

|--------|----------|-----------|│   │   └── aws_clients.py         # Clientes AWS

| `POST` | `/pedidos` | Criar novo pedido |

| `GET` | `/pedidos` | Listar todos os pedidos (com paginação e filtros) |│   │# Ler mensagens da fila

| `GET` | `/pedidos/{id}` | Buscar pedido específico |

│   └── api/                       # API Gatewayaws --endpoint-url http://localhost:4566 sqs receive-message \

### Exemplos de Uso

│       └── openapi.yaml           # Especificação OpenAPI  --queue-url "$(aws --endpoint-url http://localhost:4566 sqs get-queue-url --queue-name health-check-queue --query 'QueueUrl' --output text)"

**Criar Pedido:**

```bash│```

curl -X POST http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos \

  -H "Content-Type: application/json" \├── tests/                         # Testes

  -d '{│   ├── unit/                      # Testes unitários

    "cliente": "João Silva",│   └── integration/               # Testes de integração

    "mesa": 10,│

    "itens": ["Pizza", "Refrigerante", "Sobremesa"]├── Makefile                       # Comandos make

  }'└── README.md                      # Este arquivo

``````



**Listar Pedidos:**## 🚀 Quick Start

```bash

curl http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos?limit=5&status=processado### Pré-requisitos

```

- Docker Desktop

**Buscar Pedido:**- AWS CLI v2

```bash- jq (JSON processor)

curl http://localhost:4566/restapis/{API_ID}/prod/_user_request_/pedidos/pedido-20251112145045- PowerShell 5.1+ (Windows) ou Bash (Linux/Mac)

```

### 1. Subir LocalStack

📖 **Documentação completa:** [src/api/README.md](src/api/README.md)

```bash

## ⚡ Lambda Functionsmake up

```

### 1. criar-pedido

- **Trigger:** API Gateway (POST /pedidos)Aguarde o container ficar "healthy" (cerca de 30 segundos).

- **Função:** Valida e cria pedidos

- **Saída:** DynamoDB + SQS### 2. Provisionar Recursos AWS

- **Runtime:** Python 3.11

- **Memory:** 128 MB**Opção 1: Deploy completo**

```powershell

### 2. processar-pedido.\infra\aws\deploy-all.ps1

- **Trigger:** SQS (automático)```

- **Função:** Gera PDF do comprovante

- **Saída:** S3 + DynamoDB (atualização) + SNS**Opção 2: Deploy individual**

- **Runtime:** Python 3.11```powershell

- **Memory:** 512 MB.\infra\aws\dynamodb\create-table-pedidos.ps1

- **Dependências:** fpdf2.\infra\aws\sqs\create-queue-pedidos.ps1

.\infra\aws\s3\create-bucket-comprovantes.ps1

### 3. listar-pedidos.\infra\aws\sns\create-topic-pedidos.ps1

- **Trigger:** API Gateway (GET /pedidos)```

- **Função:** Lista e busca pedidos

- **Saída:** JSON com pedidos### 3. Testar Recursos

- **Runtime:** Python 3.11

- **Memory:** 128 MB```powershell

# Testar DynamoDB

## 📦 Recursos AWS.\infra\aws\dynamodb\test-table-pedidos.ps1



### DynamoDB - Tabela Pedidos# Testar SQS

- **Nome:** `Pedidos`.\infra\aws\sqs\test-queue-pedidos.ps1

- **Chave:** `id` (String)

- **Billing:** Pay-per-request# Testar S3

- **Campos:** id, cliente, mesa, itens, status, timestamp, comprovante_url, updated_at.\infra\aws\s3\test-bucket-comprovantes.ps1



### SQS - Fila de Pedidos# Testar SNS

- **Queue:** `pedidos-queue`.\infra\aws\sns\test-topic-pedidos.ps1

- **DLQ:** `pedidos-queue-dlq````

- **Visibility:** 30s

- **Retention:** 4 dias## 📚 Documentação

- **Max Receives:** 3

- **[Setup Completo](docs/setup.md)** - Guia detalhado de instalação

### S3 - Bucket de Comprovantes- **[Arquitetura](docs/architecture.md)** - Descrição da arquitetura do sistema

- **Nome:** `pedidos-comprovantes`- **[API](docs/api.md)** - Documentação dos endpoints

- **Versioning:** Habilitado

- **Lifecycle:** Expira após 90 dias### Documentação por Componente

- **Conteúdo:** PDFs dos comprovantes

- [Lambdas](src/lambdas/README.md) - Funções Lambda

### SNS - Notificações- [Shared](src/shared/README.md) - Código compartilhado

- **Tópico:** `PedidosConcluidos`- [API Gateway](src/api/README.md) - Configuração da API

- **Subscriptions:** Email + HTTP webhook- [DynamoDB](infra/aws/dynamodb/README.md) - Tabela de pedidos

- **Mensagem:** Detalhes do pedido processado- [SQS](infra/aws/sqs/README.md) - Fila de processamento

- [S3](infra/aws/s3/README.md) - Armazenamento de PDFs

### API Gateway- [SNS](infra/aws/sns/README.md) - Sistema de notificações

- **Tipo:** REST API

- **Stage:** prod## 🛠️ Comandos Make

- **Integração:** AWS_PROXY (Lambda)

- **CORS:** Habilitado```bash

make up          # Subir LocalStack

## 🛠️ Comandos Makemake down        # Parar LocalStack

make logs        # Ver logs do container

```bashmake bootstrap   # Provisionar recursos

make up          # Subir LocalStackmake teardown    # Remover recursos

make down        # Parar LocalStackmake doctor      # Verificar saúde do sistema

make logs        # Ver logs do container```

make bootstrap   # Provisionar recursos AWS (via scripts/)

make teardown    # Remover todos os recursos## 🔧 Configuração

make doctor      # Verificar saúde do sistema

```### LocalStack



## 🧪 Testes- **Endpoint:** http://localhost:4566

- **Região:** us-east-1

### Testar API Completa- **Credenciais:** test/test (fake para desenvolvimento local)

```powershell

.\infra\localstack\scripts\test-apigateway.ps1### Variáveis de Ambiente

```

Copie o arquivo de exemplo e ajuste conforme necessário:

### Testar Lambdas Individualmente

```powershell```bash

# Testar Lambda criar-pedidocp infra/.env.example infra/.env

.\infra\localstack\scripts\test-lambda-criar-pedido.ps1```



# Testar Lambda processar-pedido## 🧪 Testes

.\infra\localstack\scripts\test-lambda-processar-pedido.ps1

### Testes Unitários

# Testar Lambda listar-pedidos

.\infra\localstack\scripts\test-lambda-listar-pedidos.ps1```bash

```cd src/lambdas/criar-pedido

pytest tests/unit/

### Deploy Individual```

```powershell

# Deploy apenas de uma Lambda### Testes de Integração

.\infra\localstack\scripts\deploy-lambda-criar-pedido.ps1

.\infra\localstack\scripts\deploy-lambda-processar-pedido.ps1```bash

.\infra\localstack\scripts\deploy-lambda-listar-pedidos.ps1pytest tests/integration/

```

# Deploy apenas do API Gateway

.\infra\localstack\scripts\deploy-apigateway.ps1### Testes Manuais



# Deploy apenas da infraestruturaOs scripts de teste em cada componente permitem testar manualmente:

.\infra\aws\deploy-all.ps1

``````powershell

.\infra\aws\dynamodb\test-table-pedidos.ps1

## 📊 Status dos Pedidos.\infra\aws\sqs\test-queue-pedidos.ps1

.\infra\aws\s3\test-bucket-comprovantes.ps1

| Status | Descrição |.\infra\aws\sns\test-topic-pedidos.ps1

|--------|-----------|```

| `pendente` | Pedido criado, aguardando processamento |

| `processado` | PDF gerado, comprovante disponível no S3 |## 📊 Recursos AWS

| `erro` | Falha no processamento (vai para DLQ após 3 tentativas) |

### DynamoDB - Tabela Pedidos

## 📝 Logs

- **Nome:** Pedidos

### Ver logs das Lambdas- **Chave Primária:** id (String)

```powershell- **Billing:** Pay-Per-Request

# Logs em tempo real- **Atributos:** cliente, itens, mesa, status, timestamp

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/criar-pedido --region us-east-1 --follow

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/processar-pedido --region us-east-1 --follow### SQS - Fila de Pedidos

aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/listar-pedidos --region us-east-1 --follow

```- **Nome:** pedidos-queue

- **DLQ:** pedidos-queue-dlq

### Ver mensagens na DLQ- **Visibility Timeout:** 30 segundos

```powershell- **Retention:** 4 dias

aws --endpoint-url=http://localhost:4566 sqs receive-message \- **Max Receives:** 3

  --queue-url http://localhost:4566/000000000000/pedidos-queue-dlq \

  --region us-east-1### S3 - Bucket de Comprovantes

```

- **Nome:** pedidos-comprovantes

## 🐛 Troubleshooting- **Versioning:** Habilitado

- **Lifecycle:** Expiração após 90 dias

### LocalStack não inicia

```bash### SNS - Tópico de Notificações

make down

docker system prune -f- **Nome:** PedidosConcluidos

make up- **Subscriptions:** Email (cozinha) + HTTP (webhook)

```

## 🚧 Status do Projeto

### API retorna 404

- Verifique se o API ID está correto no arquivo `api-id.txt`- ✅ DynamoDB configurado e testado

- Use o formato correto: `/restapis/{API_ID}/prod/_user_request_/pedidos`- ✅ SQS configurado e testado (com DLQ)

- ✅ S3 configurado e testado (com lifecycle)

### Pedido não é processado- ✅ SNS configurado e testado (2 subscriptions)

- Verifique os logs da Lambda `processar-pedido`- ✅ Estrutura de projeto organizada

- Confirme se o SQS trigger está configurado- ✅ Documentação completa

- Veja se há mensagens na DLQ- ⏳ Lambda Criar Pedido (próxima etapa)

- ⏳ Lambda Processar Pedido (próxima etapa)

### PDF não é gerado- ⏳ API Gateway (próxima etapa)

- Verifique se o bucket S3 existe- ⏳ Testes end-to-end (próxima etapa)

- Veja os logs da Lambda para detalhes do erro

- Confirme se a dependência `fpdf2` foi instalada## 🐛 Troubleshooting



## 🔧 Configuração### LocalStack não inicia



### LocalStack```bash

- **Endpoint:** http://localhost:4566# Verificar logs

- **Região:** us-east-1make logs

- **Credenciais:** test/test (fake para desenvolvimento)

# Reiniciar container

### Variáveis de Ambientemake down

As Lambdas recebem automaticamente:make up

- `LOCALSTACK_HOSTNAME`: host.docker.internal```

- `AWS_ENDPOINT_URL`: http://host.docker.internal:4566

- `DYNAMODB_TABLE`: Pedidos### AWS CLI retorna erros

- `SQS_QUEUE_URL`: http://host.docker.internal:4566/000000000000/pedidos-queue

- `S3_BUCKET`: pedidos-comprovantes```bash

- `SNS_TOPIC_ARN`: arn:aws:sns:us-east-1:000000000000:PedidosConcluidos# Verificar se LocalStack está rodando

docker ps | grep localstack

## 📚 Documentação

# Testar conectividade

- **[API REST](src/api/README.md)** - Documentação completa da APIaws --endpoint-url=http://localhost:4566 dynamodb list-tables --region us-east-1

- **[Lambda criar-pedido](src/lambdas/criar-pedido/README.md)** - Criação de pedidos```

- **[Lambda processar-pedido](src/lambdas/processar-pedido/README.md)** - Processamento e PDF

- **[Lambda listar-pedidos](src/lambdas/listar-pedidos/README.md)** - Listagem e consulta### Recursos não foram criados



## 🎯 Fluxo End-to-End```bash

# Re-executar bootstrap

1. **Cliente** faz requisição HTTP POST para API Gatewaymake teardown

2. **API Gateway** invoca Lambda `criar-pedido`make bootstrap

3. **Lambda criar-pedido** valida dados, salva no DynamoDB e envia para SQS```

4. **SQS** armazena mensagem e dispara Lambda `processar-pedido`

5. **Lambda processar-pedido** consome SQS, gera PDF com fpdf2Para mais detalhes, consulte [docs/setup.md](docs/setup.md#troubleshooting).

6. **PDF** é salvo no S3 bucket `pedidos-comprovantes`

7. **DynamoDB** é atualizado com status `processado` e URL do comprovante## 📝 Próximos Passos

8. **SNS** publica notificação para subscriptions (email + webhook)

9. **Cliente** pode consultar pedido via GET `/pedidos/{id}` ou listar todos via GET `/pedidos`1. **Implementar Lambda Criar Pedido**

   - Criar `src/lambdas/criar-pedido/index.py`

## 🚧 Status do Projeto   - Validar entrada

   - Salvar no DynamoDB

- ✅ DynamoDB configurado e testado   - Enviar para SQS

- ✅ SQS configurado e testado (com DLQ)

- ✅ S3 configurado e testado (com lifecycle)2. **Implementar Lambda Processar Pedido**

- ✅ SNS configurado e testado (2 subscriptions)   - Criar `src/lambdas/processar-pedido/index.py`

- ✅ Lambda criar-pedido implementada e testada   - Consumir SQS

- ✅ Lambda processar-pedido implementada e testada   - Gerar PDF do comprovante

- ✅ Lambda listar-pedidos implementada e testada   - Upload no S3

- ✅ API Gateway REST configurado e testado   - Publicar notificação SNS

- ✅ Geração de PDFs com fpdf2

- ✅ Fluxo end-to-end funcionando3. **Configurar API Gateway**

- ✅ Scripts de deploy automatizados   - Criar OpenAPI spec

- ✅ Scripts de teste automatizados   - Integrar com Lambda Criar Pedido

- ✅ Documentação completa   - Configurar CORS

   - Implementar autenticação

## 🔄 Próximas Melhorias

4. **Testes End-to-End**

- [ ] Autenticação e autorização (API Key / JWT)   - Criar pedido via API

- [ ] Rate limiting no API Gateway   - Verificar processamento

- [ ] Validação de schemas com Request Validator   - Validar PDF no S3

- [ ] WebSocket para notificações em tempo real   - Confirmar notificação SNS

- [ ] Cache com ElastiCache

- [ ] Métricas e dashboards com CloudWatch## 📄 Licença

- [ ] Testes unitários com pytest

- [ ] CI/CD com GitHub ActionsEste projeto é um exemplo educacional de arquitetura serverless.

- [ ] Deploy para AWS real com Terraform/SAM

## 👥 Contribuindo

## 📄 Licença

Este é um projeto de aprendizado. Sinta-se livre para explorar e modificar!

Este projeto é um exemplo educacional de arquitetura serverless.

## 👥 Contribuindo

Este é um projeto de aprendizado. Sinta-se livre para explorar e modificar!

---

**Desenvolvido com ❤️ usando AWS Serverless e LocalStack**
