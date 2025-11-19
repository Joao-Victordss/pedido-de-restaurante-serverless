# Lambda: Criar Pedido

Função Lambda responsável por criar novos pedidos no sistema.

## 📋 Funcionalidades

1. **Validação de Payload**
   - Cliente (mínimo 3 caracteres)
   - Itens (lista com pelo menos 1 item)
   - Mesa (número inteiro > 0)

2. **Persistência no DynamoDB**
   - Gera ID único (formato: `pedido-YYYYMMDDHHMMSS`)
   - Salva com status "pendente"
   - Inclui timestamp ISO 8601

3. **Publicação no SQS**
   - Envia mensagem com dados do pedido
   - Inclui atributos de mensagem (pedidoId, status)

## 🔧 Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `AWS_ENDPOINT_URL` | Endpoint do LocalStack | `http://localhost:4566` |
| `DYNAMODB_TABLE` | Nome da tabela DynamoDB | `Pedidos` |
| `SQS_QUEUE_URL` | URL da fila SQS | `http://localhost:4566/000000000000/pedidos-queue` |

## 📥 Payload de Entrada (POST /pedidos)

```json
{
   "cliente": "João Silva",
   "mesa": 5,
   "itens": [
      { "nome": "Pizza Margherita", "quantidade": 1, "preco": 30.0 }
   ],
   "total": 30.0
}
```

## 📤 Resposta de Sucesso (201)

```json
{
  "message": "Pedido criado com sucesso",
  "pedidoId": "pedido-20251111120000",
  "status": "pendente",
  "timestamp": "2025-11-11T12:00:00.123456"
}
```

## ❌ Resposta de Erro (400)

```json
{
  "error": "Dados inválidos",
  "details": [
    "Campo \"cliente\" é obrigatório",
    "Campo \"itens\" deve ter pelo menos um item"
  ]
}
```

## 🧪 Testando Localmente

### 1. Instalar Dependências

```bash
cd src/lambdas/criar-pedido
pip install -r requirements.txt -t .
```

### 2. Invocar Lambda

```powershell
# Criar evento de teste
$event = @{
    body = '{"cliente":"João Silva","itens":["Pizza"],"mesa":5}'
} | ConvertTo-Json

# Salvar em arquivo
$event | Out-File -FilePath event.json -Encoding utf8

# Testar função
python -c "import index, json; print(json.dumps(index.handler(json.load(open('event.json')), None), indent=2))"
```

> Observação: em desenvolvimento local via CloudFormation/LocalStack, a forma mais simples de testar é usar `make test-api` ou o frontend (via `frontend/proxy.py`), que já monta o payload neste formato.

## 📊 Fluxo de Execução

```
1. API Gateway recebe POST /pedidos
   ↓
2. Lambda Criar Pedido:
   - Valida payload
   - Gera ID único
   - Salva no DynamoDB (status: pendente)
   - Envia mensagem para SQS
   ↓
3. Retorna resposta HTTP 201
   ↓
4. SQS Queue recebe mensagem
   ↓
5. Lambda Processar Pedido (próxima etapa)
```

## 🔍 Logs

A função registra logs em CloudWatch:

```
Payload recebido: {"cliente":"João Silva",...}
Criando pedido: pedido-20251111120000
Pedido salvo no DynamoDB: pedido-20251111120000
Mensagem enviada para SQS: pedido-20251111120000
```

## 🐛 Troubleshooting

### Erro: "Campo 'cliente' é obrigatório"
- Verifique se o payload contém o campo `cliente`
- Campo não pode ser vazio ou apenas espaços

### Erro: "JSON inválido"
- Verifique formatação do JSON
- Use aspas duplas, não simples
- Todos os campos string devem estar entre aspas

### Erro: "Erro interno do servidor"
- Verifique se LocalStack está rodando
- Verifique se tabela DynamoDB existe
- Verifique se fila SQS existe
- Veja logs completos para detalhes

## 📦 Deploy

Veja instruções de deploy em [src/lambdas/README.md](../README.md)

## ✅ Validações Implementadas

- [x] Cliente obrigatório (mínimo 3 caracteres)
- [x] Itens obrigatório (lista com pelo menos 1 item)
- [x] Mesa obrigatória (número inteiro > 0)
- [x] Geração de ID único
- [x] Persistência no DynamoDB
- [x] Publicação no SQS
- [x] Resposta HTTP padronizada
- [x] Headers CORS
- [x] Tratamento de erros
- [x] Logs estruturados

## 🔜 Próximos Passos

1. Deploy da Lambda no LocalStack
2. Configurar trigger do API Gateway
3. Criar testes unitários
4. Criar testes de integração
