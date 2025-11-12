# API Documentation - Sistema de Pedidos

Documentação dos endpoints da API REST.

## Base URL

```
http://localhost:4566/restapis/{api-id}/local/_user_request_
```

## Endpoints

### 1. Criar Pedido

Cria um novo pedido no sistema.

**Endpoint:** `POST /pedidos`

**Request Body:**
```json
{
  "cliente": "João Silva",
  "itens": ["Pizza Margherita", "Refrigerante"],
  "mesa": 5
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

**Validações:**
- `cliente`: string, obrigatório, mínimo 3 caracteres
- `itens`: array, obrigatório, mínimo 1 item
- `mesa`: number, obrigatório, maior que 0

**Erros:**
- `400 Bad Request`: Dados inválidos
- `500 Internal Server Error`: Erro no servidor

---

### 2. Consultar Pedido

Consulta um pedido específico por ID.

**Endpoint:** `GET /pedidos/{pedidoId}`

**Response:** `200 OK`
```json
{
  "id": "pedido-20251111120000",
  "cliente": "João Silva",
  "itens": ["Pizza Margherita", "Refrigerante"],
  "mesa": 5,
  "status": "em_preparo",
  "timestamp": "2025-11-11T12:00:00Z"
}
```

**Erros:**
- `404 Not Found`: Pedido não encontrado
- `500 Internal Server Error`: Erro no servidor

---

### 3. Listar Pedidos

Lista todos os pedidos.

**Endpoint:** `GET /pedidos`

**Query Parameters:**
- `status` (optional): Filtrar por status (pendente, em_preparo, pronto, entregue, cancelado)
- `mesa` (optional): Filtrar por mesa

**Response:** `200 OK`
```json
{
  "pedidos": [
    {
      "id": "pedido-20251111120000",
      "cliente": "João Silva",
      "mesa": 5,
      "status": "em_preparo",
      "timestamp": "2025-11-11T12:00:00Z"
    }
  ],
  "count": 1
}
```

---

### 4. Atualizar Status do Pedido

Atualiza o status de um pedido.

**Endpoint:** `PATCH /pedidos/{pedidoId}/status`

**Request Body:**
```json
{
  "status": "pronto"
}
```

**Response:** `200 OK`
```json
{
  "pedidoId": "pedido-20251111120000",
  "status": "pronto",
  "message": "Status atualizado com sucesso"
}
```

**Status válidos:**
- `pendente`: Pedido recebido
- `em_preparo`: Pedido sendo preparado
- `pronto`: Pedido pronto para entrega
- `entregue`: Pedido entregue ao cliente
- `cancelado`: Pedido cancelado

---

## Fluxo de Status

```
pendente → em_preparo → pronto → entregue
    ↓
cancelado
```

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

## Exemplos com cURL

### Criar Pedido
```bash
curl -X POST http://localhost:4566/restapis/{api-id}/local/_user_request_/pedidos \
  -H "Content-Type: application/json" \
  -d '{
    "cliente": "João Silva",
    "itens": ["Pizza", "Refri"],
    "mesa": 5
  }'
```

### Consultar Pedido
```bash
curl http://localhost:4566/restapis/{api-id}/local/_user_request_/pedidos/pedido-123
```

### Listar Pedidos
```bash
curl http://localhost:4566/restapis/{api-id}/local/_user_request_/pedidos
```

### Atualizar Status
```bash
curl -X PATCH http://localhost:4566/restapis/{api-id}/local/_user_request_/pedidos/pedido-123/status \
  -H "Content-Type: application/json" \
  -d '{"status": "pronto"}'
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
    "status": "concluido",
    "comprovanteUrl": "s3://pedidos-comprovantes/comprovantes/pedido-20251111120000-comprovante.pdf"
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
