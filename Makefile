.PHONY: help up down logs ps deploy destroy status test-api doctor clean

help:
	@echo "📦 Sistema de Pedidos - CloudFormation"
	@echo ""
	@echo "Comandos disponíveis:"
	@echo "  make up          - Subir LocalStack"
	@echo "  make down        - Parar LocalStack"
	@echo "  make logs        - Ver logs do LocalStack"
	@echo "  make deploy      - Deploy completo da stack CloudFormation"
	@echo "  make destroy     - Destruir stack CloudFormation"
	@echo "  make status      - Ver status da stack"
	@echo "  make test-api    - Testar endpoints da API"
	@echo "  make doctor      - Verificar dependências"
	@echo "  make clean       - Limpar containers e volumes"

up:
	docker compose -f infra/docker-compose.yml up -d
	@echo "⏳ Aguardando LocalStack ficar pronto (30s)..."
	@timeout /t 30 /nobreak > nul 2>&1 || sleep 30
	@echo "✅ LocalStack pronto!"

down:
	docker compose -f infra/docker-compose.yml down

logs:
	docker compose -f infra/docker-compose.yml logs -f localstack

ps:
	docker compose -f infra/docker-compose.yml ps

deploy:
	@cd infra/cloudformation && pwsh -File deploy.ps1

destroy:
	@cd infra/cloudformation && pwsh -File destroy.ps1

status:
	@aws cloudformation describe-stacks \
		--stack-name pedidos-serverless-stack \
		--endpoint-url http://localhost:4566 \
		--region us-east-1 \
		--query 'Stacks[0].[StackName,StackStatus]' \
		--output table 2>/dev/null || echo "❌ Stack não encontrada"

test-api:
	@echo "🧪 Testando API Gateway..."
	@API_ID=$$(aws apigateway get-rest-apis \
		--endpoint-url http://localhost:4566 \
		--region us-east-1 \
		--query 'items[?name==`pedidos-api`].id' \
		--output text | head -n1); \
	echo "API ID: $$API_ID"; \
	curl -X POST "http://localhost:4566/restapis/$$API_ID/dev/_user_request_/pedidos" \
		-H "Content-Type: application/json" \
		-d '{"cliente":"Test","mesa":1,"itens":[{"nome":"Pizza","quantidade":1,"preco":30.0}],"total":30.0}' \
		-w "\n%{http_code}\n"

doctor:
	@echo "🔍 Verificando dependências..."
	@docker --version > /dev/null 2>&1 || (echo "❌ Docker não encontrado" && exit 1)
	@aws --version > /dev/null 2>&1 || (echo "❌ AWS CLI não encontrado" && exit 1)
	@pwsh -Version > /dev/null 2>&1 || (echo "❌ PowerShell não encontrado" && exit 1)
	@echo "✅ Todas as dependências estão instaladas!"

clean: down
	docker compose -f infra/docker-compose.yml down -v
	@echo "🧹 Limpeza completa!"
