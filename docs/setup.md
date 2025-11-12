# Guia de Setup - Sistema de Pedidos

Este guia ajudará você a configurar o ambiente de desenvolvimento local.

## 📋 Pré-requisitos

- Docker Desktop
- AWS CLI v2
- PowerShell (Windows) ou Bash (Linux/Mac)
- jq (para processar JSON no terminal)

## 🚀 Instalação Rápida

### 1. Clonar o repositório

```bash
git clone https://github.com/Joao-Victordss/pedido-de-restaurante-serverless.git
cd pedido-de-restaurante-serverless
```

### 2. Iniciar LocalStack

```bash
make up
```

Isso irá:
- Iniciar o container do LocalStack
- Expor a porta 4566 para os serviços AWS

### 3. Provisionar infraestrutura

```bash
make bootstrap
```

Isso irá criar:
- ✅ Tabela DynamoDB: `Pedidos`
- ✅ Fila SQS: `pedidos-queue` (com DLQ)
- ✅ Bucket S3: `pedidos-comprovantes`
- ✅ Tópico SNS: `PedidosConcluidos`

## 📦 Estrutura dos Serviços

### DynamoDB - Tabela Pedidos
```bash
# Testar manualmente
.\infra\aws\dynamodb\test-table-pedidos.ps1
```

### SQS - Fila de Pedidos
```bash
# Testar manualmente
.\infra\aws\sqs\test-queue-pedidos.ps1
```

### S3 - Bucket de Comprovantes
```bash
# Testar manualmente
.\infra\aws\s3\test-bucket-comprovantes.ps1
```

### SNS - Notificações
```bash
# Testar manualmente
.\infra\aws\sns\test-topic-pedidos.ps1
```

## 🔧 Comandos Úteis

### Verificar status do LocalStack
```bash
make doctor
```

### Ver logs do LocalStack
```bash
make logs
```

### Limpar ambiente
```bash
make teardown
```

### Parar LocalStack
```bash
make down
```

## 🌐 Endpoints LocalStack

- **LocalStack**: http://localhost:4566
- **DynamoDB**: http://localhost:4566
- **SQS**: http://localhost:4566
- **S3**: http://localhost:4566
- **SNS**: http://localhost:4566

## 🔐 Credenciais (LocalStack)

```
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

## 📖 Próximos Passos

1. Verifique a [Documentação da Arquitetura](./architecture.md)
2. Implemente as funções Lambda (ver `src/lambdas/`)
3. Configure o API Gateway
4. Execute testes end-to-end

## ❗ Troubleshooting

### LocalStack não inicia
- Verifique se o Docker está rodando
- Verifique se a porta 4566 está livre

### AWS CLI não encontrado
- Reinstale o AWS CLI
- Verifique o PATH

### Erro "Expecting property name enclosed in double quotes"
- Problema com escaping de JSON no PowerShell
- Use os scripts fornecidos que já lidam com isso

## 📚 Documentação Adicional

- [Arquitetura do Sistema](./architecture.md)
- [Documentação da API](./api.md)
- [DynamoDB README](../infra/aws/dynamodb/README.md)
- [SQS README](../infra/aws/sqs/README.md)
- [S3 README](../infra/aws/s3/README.md)
- [SNS README](../infra/aws/sns/README.md)
