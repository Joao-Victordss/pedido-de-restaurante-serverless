SHELL := /bin/bash
EDGE_PORT ?= 4566
COMPOSE := docker compose -f infra/docker-compose.yml

.PHONY: up down logs ps bootstrap teardown doctor clean

up:
	$(COMPOSE) up -d
	./scripts/wait-for-localstack.sh localhost $(EDGE_PORT)

down:
	$(COMPOSE) down -v

logs:
	$(COMPOSE) logs -f localstack

ps:
	$(COMPOSE) ps

bootstrap:
	./scripts/bootstrap-local-aws.sh

teardown:
	./scripts/teardown-local-aws.sh

doctor:
	@command -v docker >/dev/null || (echo "Instale Docker" && exit 1)
	@command -v aws >/dev/null || (echo "Instale AWS CLI" && exit 1)
	@command -v jq >/dev/null || (echo "Instale jq" && exit 1)
	@echo "Ferramentas ok."

clean: down
	rm -rf .terraform terraform.tfstate* || true
