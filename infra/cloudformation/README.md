# CloudFormation - Infraestrutura como Código

Esta pasta contém a infraestrutura do projeto definida usando **AWS CloudFormation**, uma abordagem declarativa e moderna para gerenciar recursos AWS.

## 📋 O que está incluído

- **`stack.yaml`**: Template CloudFormation com todos os recursos AWS
- **`deploy.ps1`**: Script para criar/atualizar a stack
- **`destroy.ps1`**: Script para deletar a stack

## 🏗️ Recursos Criados

O template CloudFormation cria os seguintes recursos:

### 📊 DynamoDB
- **Tabela**: `Pedidos-dev`
- **Modelo de cobrança**: PAY_PER_REQUEST (on-demand)
- **Chave primária**: `id` (String, HASH)
- **Tags**: Project=RestaurantePedidos, Environment=dev

### 📬 SQS (Simple Queue Service)
- **Fila principal**: `pedidos-queue-dev`
  - Retention: 4 dias (345600s)
  - Long polling: 20s
  - Redrive policy: 3 tentativas antes de enviar para DLQ
- **Dead Letter Queue (DLQ)**: `pedidos-queue-dlq-dev`
  - Retention: 14 dias (1209600s)

### 🪣 S3 (Simple Storage Service)
- **Bucket**: `pedidos-comprovantes-dev-{AWS::AccountId}`
- **Versionamento**: Habilitado
- **Lifecycle Rules**:
  - Versões atuais: Movidas para GLACIER após 90 dias
  - Versões antigas: Expiram após 30 dias

### 📢 SNS (Simple Notification Service)
- **Tópico**: `PedidosConcluidos-dev`
- **Subscriptions**:
  - Email: `cozinha@restaurante.com`
  - HTTP: `http://localhost:3000/webhook`

## 🚀 Como usar

### 1️⃣ Criar/Atualizar Stack

```powershell
# A partir da pasta cloudformation
.\deploy.ps1
```

O script irá:
1. ✅ Verificar se LocalStack está rodando
2. 📄 Validar o template CloudFormation
3. 🔍 Detectar se a stack já existe
4. 📦 Criar nova stack OU 🔄 Atualizar stack existente
5. ⏳ Aguardar até conclusão (CREATE_COMPLETE ou UPDATE_COMPLETE)
6. 📊 Exibir outputs e recursos criados

**Características importantes:**
- ✅ **Idempotente**: Pode executar múltiplas vezes sem problemas
- 🔄 **Updates automáticos**: Detecta mudanças e aplica apenas o necessário
- 🛡️ **Rollback automático**: Se falhar, reverte para o estado anterior
- 📋 **Dependency management**: CloudFormation gerencia ordem de criação/deleção

### 2️⃣ Deletar Stack

```powershell
# A partir da pasta cloudformation
.\destroy.ps1
```

O script irá:
1. 🔍 Listar todos os recursos que serão deletados
2. ⚠️ Solicitar confirmação (digite "DELETAR")
3. 🗑️ Deletar a stack completa
4. ⏳ Aguardar até todos os recursos serem removidos

**⚠️ ATENÇÃO**: Esta operação é **DESTRUTIVA** e **PERMANENTE**!
- Todos os dados do DynamoDB serão perdidos
- Todos os arquivos do S3 serão apagados
- Mensagens em filas SQS serão perdidas

### 3️⃣ Ver informações da Stack

```powershell
# Ver status geral
aws cloudformation describe-stacks `
  --stack-name pedidos-serverless-stack `
  --endpoint-url http://localhost:4566 `
  --region us-east-1

# Ver apenas outputs
aws cloudformation describe-stacks `
  --stack-name pedidos-serverless-stack `
  --query 'Stacks[0].Outputs' `
  --endpoint-url http://localhost:4566 `
  --region us-east-1

# Listar todos os recursos
aws cloudformation list-stack-resources `
  --stack-name pedidos-serverless-stack `
  --endpoint-url http://localhost:4566 `
  --region us-east-1
```

## 📤 Outputs da Stack

A stack exporta os seguintes valores (úteis para outras stacks ou scripts):

| Output | Descrição | Exemplo |
|--------|-----------|---------|
| `PedidosTableName` | Nome da tabela DynamoDB | `Pedidos-dev` |
| `PedidosTableArn` | ARN da tabela | `arn:aws:dynamodb:...` |
| `PedidosQueueUrl` | URL da fila SQS | `http://...` |
| `PedidosQueueArn` | ARN da fila | `arn:aws:sqs:...` |
| `PedidosQueueDLQUrl` | URL da DLQ | `http://...` |
| `PedidosQueueDLQArn` | ARN da DLQ | `arn:aws:sqs:...` |
| `ComprovantesBucketName` | Nome do bucket S3 | `pedidos-comprovantes-dev-...` |
| `ComprovantesBucketArn` | ARN do bucket | `arn:aws:s3:::...` |
| `PedidosConcluidosTopicArn` | ARN do tópico SNS | `arn:aws:sns:...` |
| `PedidosConcluidosTopicName` | Nome do tópico | `PedidosConcluidos-dev` |

## ⚙️ Parâmetros

O template aceita os seguintes parâmetros:

| Parâmetro | Valores Permitidos | Default | Descrição |
|-----------|-------------------|---------|-----------|
| `Environment` | dev, staging, prod | dev | Ambiente de deploy |

Para mudar o ambiente:

```powershell
# Editar deploy.ps1 e alterar a linha:
--parameters ParameterKey=Environment,ParameterValue=prod
```

## 🔄 CloudFormation vs Scripts PowerShell

### Abordagem Atual (Scripts PowerShell)
```
infra/
  aws/
    deploy-all.ps1           # Script imperativo
    deploy-dynamodb.ps1      # Cria DynamoDB
    deploy-sqs.ps1           # Cria SQS
    deploy-s3.ps1            # Cria S3
    deploy-sns.ps1           # Cria SNS
```

**Características:**
- ❌ Imperativo (descreve "como" criar)
- ❌ Não idempotente (erro se executar 2x)
- ❌ Sem rollback automático
- ❌ Dependências manuais (ordem importa)
- ❌ Múltiplos arquivos para manter
- ✅ Controle fino sobre cada recurso

### Nova Abordagem (CloudFormation)
```
infra/
  cloudformation/
    stack.yaml              # Template declarativo
    deploy.ps1              # Deploy/Update automático
    destroy.ps1             # Cleanup completo
```

**Características:**
- ✅ Declarativo (descreve "o que" criar)
- ✅ Idempotente (pode executar múltiplas vezes)
- ✅ Rollback automático em falhas
- ✅ Dependências automáticas (!Ref, !GetAtt)
- ✅ Single source of truth (um arquivo)
- ✅ Versionável no Git
- ✅ Updates incrementais (muda só o necessário)
- ✅ Drift detection (detecta mudanças manuais)

### Comparação Prática

#### Criar recursos

**Scripts PowerShell:**
```powershell
.\infra\aws\deploy-dynamodb.ps1  # Erro se já existir
.\infra\aws\deploy-sqs.ps1       # Erro se já existir
.\infra\aws\deploy-s3.ps1        # Erro se já existir
.\infra\aws\deploy-sns.ps1       # Erro se já existir
```

**CloudFormation:**
```powershell
.\infra\cloudformation\deploy.ps1  # Cria OU atualiza automaticamente
```

#### Atualizar configuração (ex: mudar retention de SQS de 4 para 7 dias)

**Scripts PowerShell:**
1. Editar `deploy-sqs.ps1`
2. Deletar fila manualmente
3. Executar script novamente
4. ❌ Dados perdidos!

**CloudFormation:**
1. Editar `stack.yaml` (MessageRetentionPeriod: 604800)
2. Executar `.\deploy.ps1`
3. ✅ CloudFormation atualiza sem deletar a fila!

#### Deletar tudo

**Scripts PowerShell:**
```powershell
# Sem script de cleanup - manual no console AWS
```

**CloudFormation:**
```powershell
.\infra\cloudformation\destroy.ps1  # Remove tudo automaticamente
```

## 🔀 Migração dos Scripts

Atualmente, **ambas as abordagens coexistem**. Você pode usar:

1. **Scripts PowerShell** (em `infra/aws/`)
   - Use se precisar de controle fino
   - Use se estiver migrando gradualmente

2. **CloudFormation** (nesta pasta)
   - Use para novos ambientes (staging, prod)
   - Use para deployments repetíveis
   - Use para infraestrutura versionada no Git

### Plano de Migração

```
Fase 1: ✅ ATUAL
  - CloudFormation criado
  - Scripts PowerShell mantidos
  - Ambos funcionando em paralelo

Fase 2: 🔄 FUTURA
  - Testar CloudFormation em dev
  - Comparar recursos criados
  - Validar outputs e integrações

Fase 3: 🎯 FINAL
  - Migrar dev para CloudFormation
  - Criar ambientes staging e prod
  - Deprecar scripts PowerShell
  - Mover scripts para pasta "legacy/"
```

## 🐛 Troubleshooting

### Erro: "Stack já existe"
✅ **Normal!** O script detecta e atualiza automaticamente.

### Erro: "No updates are to be performed"
✅ **Normal!** A stack já está no estado desejado.

### Erro: "LocalStack não está rodando"
```powershell
# Iniciar LocalStack
docker compose -f infra/docker-compose.yml up -d

# Verificar saúde
curl http://localhost:4566/_localstack/health
```

### Stack travada em "CREATE_IN_PROGRESS"
```powershell
# Verificar eventos da stack
aws cloudformation describe-stack-events `
  --stack-name pedidos-serverless-stack `
  --endpoint-url http://localhost:4566 `
  --region us-east-1 `
  --max-items 20

# Cancelar update se necessário
aws cloudformation cancel-update-stack `
  --stack-name pedidos-serverless-stack `
  --endpoint-url http://localhost:4566 `
  --region us-east-1
```

### Ver logs de erros
```powershell
# Eventos da stack (últimos 20)
aws cloudformation describe-stack-events `
  --stack-name pedidos-serverless-stack `
  --endpoint-url http://localhost:4566 `
  --region us-east-1 `
  --max-items 20 `
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`]'
```

## 📚 Recursos Adicionais

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [CloudFormation Template Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html)
- [LocalStack CloudFormation](https://docs.localstack.cloud/user-guide/aws/cloudformation/)
- [CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)

## 🎯 Próximos Passos

1. **Testar deploy**: Execute `.\deploy.ps1` e valide todos os recursos
2. **Validar idempotência**: Execute `.\deploy.ps1` novamente (deve dizer "No updates")
3. **Testar updates**: Altere algo no `stack.yaml` e execute `.\deploy.ps1`
4. **Integrar Lambdas**: Adicionar Lambdas ao CloudFormation (futuro)
5. **Adicionar API Gateway**: Incluir API Gateway no template (futuro)
6. **Multi-ambiente**: Criar stacks para staging e prod

---

**Dica**: Use CloudFormation para infraestrutura base (DynamoDB, S3, SQS, SNS) e mantenha Lambdas/API Gateway nos scripts por enquanto. Migre gradualmente!
