# API Documentation - Sistema de Pedidos

Documentação dos endpoints da API REST.

## Base URL (LocalStack)

No ambiente local com LocalStack e a stack CloudFormation deste projeto, a API REST é criada com o nome `pedidos-api` e stage `dev`.

```
http://localhost:4566/restapis/{API_ID}/dev/_user_request_
```

## Endpoints

### 1. Criar Pedido

Cria um novo pedido no sistema.

**Endpoint:** `POST /pedidos`

**Request Body (modelo atual):**
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

**Response:** `201 Created`
```json
{
  "pedidoId": "pedido-20251111120000",
  "status": "pendente",
  "timestamp": "2025-11-11T12:00:00Z",
  "message": "Pedido criado com sucesso"
}
```

**Validações (Lambda criar-pedido):**
- `cliente`: string, obrigatório, mínimo 3 caracteres
- `mesa`: number, obrigatório, maior que 0
- `itens`: array de objetos, obrigatório, mínimo 1 item, cada item com `nome`, `quantidade`, `preco`
- `total`: number, obrigatório, soma aproximada dos itens

**Erros:**
- `400 Bad Request`: Dados inválidos
- `500 Internal Server Error`: Erro no servidor

---

### 2. Listar Pedidos

Lista pedidos com paginação e filtro de status.

**Endpoint:** `GET /pedidos`

**Query Parameters:**
- `status` (opcional): Filtrar por status (`pendente`, `processado`, `erro`)
- `limit` (opcional): Número máximo de resultados (padrão: 50)
- `lastKey` (opcional): chave para paginação

**Response:** `200 OK`
```json
{
  "pedidos": [
    {
      "id": "pedido-20251111120000",
      "cliente": "João Silva",
      "mesa": 5,
      "status": "processado",
      "timestamp": "2025-11-11T12:00:00Z",
      "itens": [
        { "nome": "Pizza Margherita", "quantidade": 1, "preco": 30.0 }
      ],
      "updated_at": "2025-11-11T12:05:00Z",
      "comprovante_url": "comprovantes/pedido-20251111120000.pdf"
    }
  ],
  "count": 1,
  "lastKey": "pedido-20251111120000"
}
```

> Observação: a versão atual exposta pela stack CloudFormation implementa somente `GET /pedidos` (listagem). Um endpoint `GET /pedidos/{id}` pode ser adicionado futuramente se necessário.

## Headers

Todas as requisições devem incluir:

```
Content-Type: application/json
```

## Códigos de Status HTTP

- `200 OK`: Requisição bem-sucedida
- `201 Created`: Recurso criado com sucesso
- `400 Bad Request`: Dados de entrada inválidos
- `404 Not Found`: Recurso não encontrado
- `500 Internal Server Error`: Erro interno do servidor

## Exemplos com cURL (LocalStack)

### Criar Pedido
```bash
curl -X POST http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos \
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

### Listar Pedidos
```bash
curl http://localhost:4566/restapis/{API_ID}/dev/_user_request_/pedidos?status=processado&limit=10
```

## Webhooks (SNS)

Quando um pedido é concluído, o sistema envia notificações via SNS:

**Formato da Notificação:**
```json
{
  "TopicArn": "arn:aws:sns:us-east-1:000000000000:PedidosConcluidos",
  "Message": {
    "pedidoId": "pedido-20251111120000",
    "cliente": "João Silva",
    "mesa": 5,
    "status": "processado",
    "comprovanteUrl": "s3://pedidos-comprovantes/comprovantes/pedido-20251111120000.pdf"
  },
  "Subject": "Pedido Pronto!"
}
```

## Rate Limiting

Atualmente não há rate limiting configurado no LocalStack.

Em produção, recomenda-se:
- API Gateway Throttling: 1000 requests/segundo
- Burst: 2000 requests

## Segurança

⚠️ **LocalStack**: Não há autenticação configurada.

Em produção, implementar:
- API Keys via API Gateway
- Cognito User Pools
- IAM Authorization
- HTTPS obrigatório
