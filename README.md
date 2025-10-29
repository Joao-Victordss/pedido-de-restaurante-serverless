# Pedido Restaurante

## Ambiente local com LocalStack

Pré-requisitos: Docker, AWS CLI, jq.

Passos:
1. Copie variáveis de ambiente:
   ```bash
   cp infra/.env.example infra/.env
   ```

Suba o LocalStack e aguarde o healthcheck:

```
make up
```

Bootstrap de recursos básicos:

```
make bootstrap
```

Ver logs:

```
make logs
```

Limpar recursos e encerrar:

```
make teardown
make down
```

Endpoints: http://localhost:4566

Região: us-east-1

Credenciais: definidas em infra/.env (fakes para uso local).

---

## Como o Copilot deve atuar
- Abra cada arquivo no caminho indicado e cole o conteúdo.
- O Copilot completa pequenos ajustes e comentários se você escrever cabeçalhos como “// TODO: criar recursos app na Issue 3+”.
- Use as tasks do VS Code: Ctrl+Shift+P > Run Task > “LocalStack: Up” > “LocalStack: Bootstrap”.

## Teste rápido
Depois de `make bootstrap`:
```
# Ver arquivo de teste no S3
aws --endpoint-url http://localhost:4566 s3 ls s3://health-check-bucket/

# Ler mensagens da fila
aws --endpoint-url http://localhost:4566 sqs receive-message \
  --queue-url "$(aws --endpoint-url http://localhost:4566 sqs get-queue-url --queue-name health-check-queue --query 'QueueUrl' --output text)"
```
