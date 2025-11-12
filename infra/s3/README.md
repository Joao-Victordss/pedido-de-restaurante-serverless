# S3 - Bucket para Comprovantes de Pedidos

Bucket S3 para armazenar comprovantes de pedidos em PDF.

## 📋 Configuração do Bucket

### Bucket: `pedidos-comprovantes`

```yaml
Nome: pedidos-comprovantes
Região: us-east-1
Versionamento: Habilitado
Ciclo de vida: 90 dias (arquivos expiram automaticamente)
```

## 📁 Estrutura de Armazenamento

```
pedidos-comprovantes/
├── comprovantes/
│   ├── pedido-20251111120000-comprovante.pdf
│   ├── pedido-20251111120100-comprovante.pdf
│   └── ...
```

### Convenção de Nomes:
- **Formato**: `comprovantes/{pedidoId}-comprovante.pdf`
- **Exemplo**: `comprovantes/pedido-20251111120000-comprovante.pdf`

## 🚀 Como Usar

### Criar o Bucket

**PowerShell:**
```powershell
.\infra\s3\create-bucket-comprovantes.ps1
```

**Bash:**
```bash
./infra/s3/create-bucket-comprovantes.sh
```

### Testar o Bucket

```powershell
.\infra\s3\test-bucket-comprovantes.ps1
```

O script de teste executa:
1. ✅ Criação de arquivo de comprovante simulado
2. ✅ Upload para S3
3. ✅ Listagem de objetos
4. ✅ Download de S3
5. ✅ Verificação de integridade
6. ✅ Obtenção de metadados
7. ✅ Geração de URL pré-assinada
8. ✅ Deleção de objeto

## 🔄 Fluxo de Processamento

```
Lambda Processar Pedido
         ↓
    Gera PDF do comprovante
         ↓
    Upload para S3
         ↓
s3://pedidos-comprovantes/comprovantes/{pedidoId}-comprovante.pdf
         ↓
    Retorna URL pré-assinada
         ↓
    Cliente acessa o comprovante
```

## 📊 Características

- **Versionamento**: Mantém histórico de versões dos arquivos
- **Ciclo de Vida**: Arquivos expiram automaticamente após 90 dias
- **URLs Pré-assinadas**: Acesso temporário seguro aos arquivos (válido por 1 hora)
- **Metadados**: Informações sobre tamanho, tipo, data de modificação

## 🔧 Comandos Úteis

### Upload de arquivo:

```bash
aws s3 cp comprovante.pdf s3://pedidos-comprovantes/comprovantes/pedido-123-comprovante.pdf \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Download de arquivo:

```bash
aws s3 cp s3://pedidos-comprovantes/comprovantes/pedido-123-comprovante.pdf ./comprovante.pdf \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Listar arquivos:

```bash
aws s3 ls s3://pedidos-comprovantes/comprovantes/ \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Gerar URL pré-assinada:

```bash
aws s3 presign s3://pedidos-comprovantes/comprovantes/pedido-123-comprovante.pdf \
  --expires-in 3600 \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Deletar arquivo:

```bash
aws s3 rm s3://pedidos-comprovantes/comprovantes/pedido-123-comprovante.pdf \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### Obter metadados:

```bash
aws s3api head-object \
  --bucket pedidos-comprovantes \
  --key comprovantes/pedido-123-comprovante.pdf \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

## 📄 Formato do Comprovante

Exemplo de comprovante gerado:

```
==========================================
    COMPROVANTE DE PEDIDO
==========================================

Pedido ID: pedido-20251111120000
Data/Hora: 11/11/2025 12:00:00
Cliente: João Silva
Mesa: 5

ITENS DO PEDIDO:
- Pizza Margherita ......... R$ 35,00
- Refrigerante ............. R$ 8,00

------------------------------------------
TOTAL ........................ R$ 43,00
==========================================

Obrigado pela preferência!
==========================================
```

## 🔐 Segurança

- URLs pré-assinadas expiram após 1 hora
- Acesso controlado via IAM (em produção)
- Versionamento permite recuperação de arquivos sobrescritos
- Ciclo de vida garante que arquivos antigos sejam removidos

## 🎯 Integração com Lambda

A Lambda de processamento deve:

1. Receber dados do pedido da fila SQS
2. Gerar PDF do comprovante (pode usar bibliotecas como `fpdf` ou `reportlab`)
3. Fazer upload para S3:
   ```python
   import boto3
   
   s3 = boto3.client('s3', endpoint_url='http://localhost:4566')
   s3.put_object(
       Bucket='pedidos-comprovantes',
       Key=f'comprovantes/{pedido_id}-comprovante.pdf',
       Body=pdf_content
   )
   ```
4. Gerar URL pré-assinada para retornar ao cliente
5. Enviar notificação via SNS

## 📈 Monitoramento

Para monitorar o bucket em produção:

- CloudWatch Metrics: Número de objetos, tamanho total
- S3 Access Logs: Registrar acessos aos arquivos
- S3 Event Notifications: Notificar sobre uploads/deletes

## 🎯 Próximos Passos

1. ✅ Bucket S3 criado e configurado
2. ✅ Implementar Lambda para gerar PDFs
3. ✅ Integrar com SQS para processar pedidos
4. ✅ Configurar notificações S3 (opcional)
5. ✅ Adicionar tags aos objetos para organização
