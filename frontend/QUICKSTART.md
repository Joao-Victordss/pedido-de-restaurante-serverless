# 🚀 Quick Start - Frontend

## Seu API ID atual:
```
dp2g1h6fv4
```

## Como usar:

### 1. Abra o frontend
O arquivo `index.html` já deve estar aberto no seu navegador.
Se não estiver, execute:
```powershell
Start-Process ".\frontend\index.html"
```

### 2. Configure o API ID
1. Cole este ID no campo "API Gateway ID": **dp2g1h6fv4**
2. Clique em "Salvar"
3. A URL da API aparecerá abaixo

### 3. Teste!
- **Criar Pedido**: Preencha o formulário e clique em "Criar Pedido"
- **Listar Pedidos**: Clique em "🔄 Atualizar" para ver todos os pedidos
- **Ver Detalhes**: Clique em qualquer card de pedido
- **Auto-refresh**: Clique em "▶️ Auto-refresh" para atualizar automaticamente

## 🎯 Fluxo Completo

1. Crie um pedido novo
2. Aguarde 5-10 segundos
3. Clique em "Atualizar" 
4. Veja o pedido mudar de "PENDENTE" para "PROCESSADO"
5. Clique no card do pedido para ver detalhes
6. Baixe o PDF do comprovante

## 📱 Features

- ✅ Criar pedidos com múltiplos itens
- ✅ Listar pedidos com paginação
- ✅ Filtrar por status (pendente, processado, erro)
- ✅ Ver detalhes completos
- ✅ Auto-refresh a cada 5 segundos
- ✅ Download de comprovantes PDF
- ✅ Interface responsiva

## 🐛 Problemas?

Se algo não funcionar:

1. **Verifique o LocalStack**: `docker ps`
2. **Teste a API manualmente**:
   ```powershell
   # Listar pedidos
   Invoke-WebRequest -Uri "http://localhost:4566/restapis/dp2g1h6fv4/prod/_user_request_/pedidos?limit=5" -UseBasicParsing
   ```
3. **Veja o console do navegador**: F12 → Console (para ver erros)

---

**Aproveite! 🎉**
