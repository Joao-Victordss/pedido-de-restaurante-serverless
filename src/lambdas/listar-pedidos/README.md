# Lambda Listar Pedidos

Lambda function para listar e buscar pedidos via API Gateway.

## Funcionalidades

1. **Listar pedidos**: `GET /pedidos`
2. **Filtrar por status**: `GET /pedidos?status=processado`
3. **Paginação**: `GET /pedidos?limit=10&lastKey=pedido-xxx`

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `LOCALSTACK_HOSTNAME` | Hostname do LocalStack | `localhost` |
| `AWS_ENDPOINT_URL` | Endpoint dos serviços AWS | `http://localhost:4566` |
| `DYNAMODB_TABLE` | Nome da tabela DynamoDB | `Pedidos` |

## Endpoints

### GET /pedidos

Lista todos os pedidos ordenados por timestamp (mais recente primeiro).

**Query Parameters:**
- `limit` (opcional): Número máximo de resultados (padrão: 50)
- `lastKey` (opcional): Chave do último item para paginação
- `status` (opcional): Filtrar por status (`pendente`, `processado`, `erro`)

**Resposta de Sucesso (200):**
```json
{
  "pedidos": [
    {
      "id": "pedido-20241112010203",
      "cliente": "João Silva",
      "mesa": 5,
      "status": "processado",
      "timestamp": "2024-11-12T01:02:03.456789",
      "itens": ["Pizza", "Refrigerante"],
      "updated_at": "2024-11-12T01:02:10.123456",
      "comprovante_url": "comprovantes/pedido-20241112010203.pdf"
    }
  ],
  "count": 1,
  "lastKey": "pedido-20241112010203"
}
```

## Exemplos de Uso

### Listar todos os pedidos
```bash
curl http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos
```

### Buscar pedido específico
```bash
curl http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos?status=processado
```

### Com paginação
```bash
curl "http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos?limit=10&lastKey=pedido-20241112010203"
```

## Códigos de Resposta

- `200 OK` - Pedido(s) encontrado(s)
- `500 Internal Server Error` - Erro no servidor

## Deploy

> Observação: no fluxo atual com CloudFormation, a Lambda `listar-pedidos` é criada/atualizada junto com a stack via `make deploy`. Use `make test-api` ou o frontend para exercitar os endpoints.
