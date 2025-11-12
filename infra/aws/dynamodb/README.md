# Tabela DynamoDB: Pedidos

## 📋 Estrutura da Tabela

### Schema da Tabela
```
Nome: Pedidos
Chave Primária: id (String)
Billing Mode: PAY_PER_REQUEST (On-Demand)
```

### Atributos do Pedido

| Atributo | Tipo | Descrição | Exemplo |
|----------|------|-----------|---------|
| `id` | String (PK) | Identificador único do pedido | `"pedido-20251111123456"` |
| `cliente` | String | Nome do cliente | `"João Silva"` |
| `itens` | List | Lista de itens do pedido | `["Pizza", "Refri"]` |
| `mesa` | Number | Número da mesa | `5` |
| `status` | String | Status do pedido | `"pendente"`, `"em_preparo"`, `"pronto"`, `"entregue"` |
| `timestamp` | String | Data/hora da criação | `"2025-11-11T12:34:56Z"` |

### Estados Possíveis do Status
- `pendente` - Pedido recebido, aguardando processamento
- `em_preparo` - Pedido sendo preparado na cozinha
- `pronto` - Pedido pronto para entrega
- `entregue` - Pedido entregue ao cliente
- `cancelado` - Pedido cancelado

## 🚀 Como Usar

### 1. Criar a Tabela
```powershell
# No Windows (PowerShell)
.\infra\dynamodb\create-table-pedidos.ps1

# No Linux/Mac (Bash)
./infra/dynamodb/create-table-pedidos.sh
```

### 2. Testar a Tabela
```powershell
.\infra\dynamodb\test-table-pedidos.ps1
```

### 3. Comandos Úteis

#### Listar todos os pedidos
```powershell
aws dynamodb scan `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --output json
```

#### Consultar um pedido específico
```powershell
aws dynamodb get-item `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --key '{"id": {"S": "pedido-123"}}' `
  --output json
```

#### Inserir um novo pedido
```powershell
aws dynamodb put-item `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --item '{
    "id": {"S": "pedido-123"},
    "cliente": {"S": "Maria Santos"},
    "itens": {"L": [{"S": "Hamburguer"}, {"S": "Batata Frita"}]},
    "mesa": {"N": "3"},
    "status": {"S": "pendente"},
    "timestamp": {"S": "2025-11-11T12:00:00Z"}
  }'
```

#### Atualizar status do pedido
```powershell
aws dynamodb update-item `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --key '{"id": {"S": "pedido-123"}}' `
  --update-expression "SET #status = :status" `
  --expression-attribute-names '{"#status": "status"}' `
  --expression-attribute-values '{":status": {"S": "em_preparo"}}' `
  --return-values ALL_NEW
```

#### Deletar a tabela
```powershell
aws dynamodb delete-table `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos
```

## 🧪 Exemplo de Dados

### Pedido Completo
```json
{
  "id": "pedido-20251111123456",
  "cliente": "João Silva",
  "itens": ["Pizza Margherita", "Refrigerante", "Sobremesa"],
  "mesa": 5,
  "status": "pendente",
  "timestamp": "2025-11-11T12:34:56Z"
}
```

## 📊 Consultas Comuns

### Pedidos por Status
```powershell
aws dynamodb scan `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --filter-expression "#status = :status" `
  --expression-attribute-names '{"#status": "status"}' `
  --expression-attribute-values '{":status": {"S": "pendente"}}' `
  --output json
```

### Contar total de pedidos
```powershell
aws dynamodb scan `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --select COUNT `
  --output json
```

## 🔍 Verificar se a Tabela Existe
```powershell
aws dynamodb describe-table `
  --endpoint-url http://localhost:4566 `
  --table-name Pedidos `
  --query 'Table.[TableName,TableStatus,ItemCount]' `
  --output json
```
