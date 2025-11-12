# 🚀 Quick Start

## Passo a Passo Rápido

### 1️⃣ Subir o LocalStack
```powershell
make up
# ou
docker compose -f infra/docker-compose.yml up -d
```

### 2️⃣ Deploy do Backend
```powershell
.\infra\localstack\scripts\deploy-all.ps1
```

Isso vai:
- Criar DynamoDB, S3, SQS
- Fazer deploy das 3 Lambdas
- Criar API Gateway REST
- Configurar tudo

### 3️⃣ Rodar o Frontend
```powershell
cd frontend
python proxy.py
```

### 4️⃣ Abrir no Navegador
```
http://localhost:8080/index.html
```

### 5️⃣ Testar
1. Crie um pedido (cliente, mesa, itens)
2. Clique em "Criar Pedido"
3. Veja o pedido aparecer com status "pendente"
4. Aguarde ~5s e veja mudar para "processado"
5. Clique no card para ver detalhes
6. Clique em "Download Comprovante" se disponível

---

## 🔧 Comandos Úteis

### Ver logs do LocalStack
```powershell
make logs
```

### Testar API manualmente
```powershell
# Listar pedidos
Invoke-WebRequest -Uri "http://localhost:8080/api/pedidos?limit=10" -UseBasicParsing

# Criar pedido
$body = @{ cliente = "João"; mesa = 5; itens = @("Pizza", "Refrigerante") } | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/pedidos" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
```

### Derrubar tudo
```powershell
make down
```

---

## ❓ Problemas?

### Porta 8080 em uso
Mude a porta no `frontend/proxy.py` (linha `PORT = 8080`)

### API não encontrada
Execute novamente:
```powershell
.\infra\localstack\scripts\deploy-apigateway.ps1
```

### Pedidos não processam
Verifique se a Lambda processar-pedido está rodando:
```powershell
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

---

✅ **Pronto! Aplicação funcionando em 5 passos!**
