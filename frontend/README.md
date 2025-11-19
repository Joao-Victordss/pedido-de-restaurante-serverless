# Frontend - Sistema de Pedidos# Frontend - Sistema de Pedidos



Frontend web simples para testar a API de pedidos do restaurante.Interface web simples para testar e interagir com a API de pedidos do restaurante.



## 🚀 Como Usar## 🎨 Features



### Opção 1: Com Proxy (Recomendado - Sem configuração manual!)- ✅ **Criar Pedidos** - Interface intuitiva para criar novos pedidos

- ✅ **Listar Pedidos** - Visualização em cards com filtros e paginação

O proxy descobre automaticamente o API ID do LocalStack:- ✅ **Detalhes do Pedido** - Modal com informações completas

- ✅ **Filtros** - Por status (pendente, processado, erro)

```powershell- ✅ **Paginação** - Navegação entre páginas de resultados

# Iniciar o proxy server- ✅ **Auto-refresh** - Atualização automática a cada 5 segundos

cd frontend- ✅ **Download de Comprovantes** - Link para baixar PDF do S3

python proxy.py- ✅ **Responsivo** - Funciona em desktop e mobile

```

## 🚀 Como Usar

Então abra no navegador: **http://localhost:8080/index.html**

### 1. Abrir o Frontend

**Pronto!** Não precisa configurar nada, o proxy já sabe qual API usar! 🎉

Simplesmente abra o arquivo `index.html` no seu navegador:

### Opção 2: Iniciar com Script Automático

```bash

Ainda mais fácil:# Windows

start frontend/index.html

```powershell

.\frontend\start.ps1# Mac/Linux

```open frontend/index.html

```

Este script verifica tudo e inicia o proxy automaticamente!

Ou use um servidor HTTP simples:

## ✨ Funcionalidades

```bash

- ✅ **Criar Pedidos**: Adicione cliente, mesa e itens# Python

- ✅ **Listar Pedidos**: Veja todos os pedidos com paginaçãocd frontend

- ✅ **Filtros**: Por status (pendente, processado, erro) e limitepython -m http.server 8080

- ✅ **Detalhes**: Clique em um pedido para ver informações completas

- ✅ **Auto-atualizar**: Atualização automática a cada 5 segundos# Node.js (http-server)

- ✅ **Download**: Baixe o comprovante PDF quando disponívelnpx http-server frontend -p 8080

- ✅ **Responsivo**: Funciona em desktop e mobile```



## 🎨 DesignAcesse: http://localhost:8080



- Interface limpa e moderna### 2. Configurar API ID

- Tema roxo/violeta com gradientes

- Cards para cada pedido1. No campo "API Gateway ID", cole o ID da sua API

- Badges coloridas por status2. Você encontra o ID no arquivo `api-id.txt` na raiz do projeto

- Modal para detalhes3. Ou ao final do deploy: `.\infra\localstack\scripts\deploy-all.ps1`

- Animações suaves4. Clique em "Salvar"



## 🔧 TecnologiasO ID fica salvo no localStorage do navegador.



- **HTML5**: Estrutura semântica### 3. Criar um Pedido

- **CSS3**: Estilização com variáveis CSS e grid

- **JavaScript (ES6+)**: Lógica e integração com API1. Preencha o nome do cliente (mínimo 3 caracteres)

- **Python 3**: Servidor proxy2. Digite o número da mesa (maior que 0)

- **Fetch API**: Requisições HTTP3. Adicione itens do pedido (clique em "+ Adicionar Item" para mais itens)

4. Clique em "Criar Pedido"

## 📁 Arquivos

O pedido será criado e processado automaticamente em background!

```

frontend/### 4. Visualizar Pedidos

├── index.html      # Estrutura da aplicação

├── styles.css      # Estilos e design- **Filtrar por Status**: Escolha pendente, processado ou erro

├── script.js       # Lógica e API- **Ajustar Limite**: Escolha quantos pedidos exibir (5, 10, 20, 50)

├── proxy.py        # Servidor proxy (recomendado)- **Atualizar**: Clique em 🔄 para recarregar

├── start.ps1       # Script para iniciar tudo- **Auto-refresh**: Clique em ▶️ para ativar atualização automática (5s)

└── README.md       # Esta documentação- **Paginação**: Use os botões "Anterior" e "Próxima" para navegar

```

### 5. Ver Detalhes

## 🐛 Troubleshooting

Clique em qualquer card de pedido para ver:

### Proxy não inicia- Todas as informações do pedido

- Status atual

**Erro**: `AWS CLI não encontrado`- Timestamps

- **Solução**: Instale o AWS CLI- Lista completa de itens

- Link para download do comprovante (se processado)

**Erro**: `API 'pedidos-api' não encontrada`

- **Solução**: Execute o deploy do API Gateway:## 📸 Screenshots

  ```powershell

  .\infra\localstack\scripts\deploy-apigateway.ps1### Tela Principal

  ```- Interface limpa com gradiente moderno

- Formulário de criação de pedidos

### Pedidos não aparecem- Grid de cards com pedidos



1. Verifique se o LocalStack está rodando:### Cards de Pedido

   ```powershell- Código do pedido

   docker ps- Badge colorido de status

   ```- Informações do cliente e mesa

- Lista de itens (até 3 visíveis)

2. Verifique se as Lambdas estão deployadas:

   ```powershell### Modal de Detalhes

   .\infra\localstack\scripts\deploy-all.ps1- Informações completas

   ```- Botão para baixar PDF do comprovante



## 💡 Dicas## 🎨 Design



1. **Use o proxy**: É muito mais prático!- **Cores Principais**:

2. **F12**: DevTools para ver requisições e erros  - Verde (#4CAF50) - Sucesso/Processado

3. **Auto-refresh**: Veja pedidos sendo processados em tempo real  - Azul (#2196F3) - Ações secundárias

4. **Limite**: Use 5-10 para testar paginação  - Vermelho (#f44336) - Erros/Remover

  - Amarelo (#ff9800) - Pendente

## 📝 Exemplo de Uso

- **Layout**:

1. Inicie: `cd frontend && python proxy.py`  - Responsivo (mobile-first)

2. Abra: `http://localhost:8080/index.html`  - Cards com hover effect

3. Crie um pedido com cliente, mesa e itens  - Modal para detalhes

4. Veja o status mudar de "pendente" para "processado"  - Animações suaves

5. Clique no card para ver detalhes

- **Tipografia**:

🎉 **Pronto!**  - Font: Segoe UI

  - Tamanhos variados para hierarquia
  - Emojis para melhor UX

## 🔧 Tecnologias

- **HTML5** - Estrutura semântica
- **CSS3** - Estilização moderna (Grid, Flexbox, Animations)
- **JavaScript Vanilla** - Sem frameworks, puro
- **Fetch API** - Requisições HTTP
- **LocalStorage** - Persistência do API ID

## 🐛 Troubleshooting

### Erro de CORS
Se você ver erros de CORS no console:
- Certifique-se de que o LocalStack está rodando
- A API Gateway deve ter CORS habilitado (já configurado)
- Use um servidor HTTP local se abrir o HTML direto causar problemas

### API ID não funciona
- Verifique se o LocalStack está rodando: `docker ps`
- Confirme que o API Gateway foi deployado
- Verifique o ID no arquivo `api-id.txt`
- URL deve ser: `http://localhost:4566/restapis/{API_ID}/prod/_user_request_`

### Pedidos não aparecem
- Clique em "🔄 Atualizar"
- Verifique se há pedidos no DynamoDB:
  ```bash
  aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name Pedidos --region us-east-1
  ```
- Veja os logs da Lambda listar-pedidos

### Comprovante não baixa
- Certifique-se de que o pedido está com status "processado"
- Verifique se o PDF existe no S3:
  ```bash
  aws --endpoint-url=http://localhost:4566 s3 ls s3://pedidos-comprovantes/comprovantes/
  ```

## 📝 Arquivos

```
frontend/
├── index.html      # Estrutura HTML
├── styles.css      # Estilos CSS
├── script.js       # Lógica JavaScript
└── README.md       # Este arquivo
```

## 🔄 Fluxo de Uso Típico

1. **Configurar** - Cole o API ID e salve
2. **Criar Pedido** - Preencha o formulário e crie
3. **Aguardar** - O pedido é processado automaticamente (5-10 segundos)
4. **Atualizar** - Clique em atualizar ou use auto-refresh
5. **Verificar Status** - Veja o pedido mudar de "pendente" para "processado"
6. **Ver Detalhes** - Clique no card para ver tudo
7. **Baixar PDF** - Clique em "Baixar Comprovante"

## 💡 Dicas

- Use **auto-refresh** para ver pedidos sendo processados em tempo real
- **Filtros** ajudam a encontrar pedidos específicos rapidamente
- **Paginação** mantém a interface rápida mesmo com muitos pedidos
- O **API ID é salvo** no navegador, não precisa digitar toda vez
- **Múltiplos itens** podem ser adicionados ao pedido

## 🚀 Melhorias Futuras

- [ ] Editar pedidos existentes
- [ ] Cancelar pedidos
- [ ] Histórico de ações
- [ ] Notificações em tempo real (WebSocket)
- [ ] Estatísticas e dashboards
- [ ] Impressão de comprovantes
- [ ] Temas (claro/escuro)
- [ ] PWA (Progressive Web App)

---

**Desenvolvido com ❤️ para testar APIs Serverless**
