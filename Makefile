.PHONY: help up down up-clickhouse down-clickhouse up-signoz down-signoz restart restart-clickhouse restart-signoz logs logs-clickhouse logs-signoz ps env

help: ## Показать справку
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# === Полный стенд ===

up: up-clickhouse up-signoz ## Запустить весь стенд (ClickHouse + SigNoz)

down: down-signoz down-clickhouse ## Остановить весь стенд

restart: down up ## Перезапустить весь стенд

# === ClickHouse ===

up-clickhouse: ## Запустить ClickHouse
	docker compose -f clickhouse/docker-compose.yml up -d

down-clickhouse: ## Остановить ClickHouse
	docker compose -f clickhouse/docker-compose.yml down

restart-clickhouse: down-clickhouse up-clickhouse ## Перезапустить ClickHouse

logs-clickhouse: ## Логи ClickHouse (follow)
	docker compose -f clickhouse/docker-compose.yml logs -f

# === SigNoz ===

up-signoz: env ## Запустить SigNoz
	docker compose -f signoz/docker-compose.yml up -d

down-signoz: ## Остановить SigNoz
	docker compose -f signoz/docker-compose.yml down

restart-signoz: down-signoz up-signoz ## Перезапустить SigNoz

logs-signoz: ## Логи SigNoz (follow)
	docker compose -f signoz/docker-compose.yml logs -f

# === Утилиты ===

logs: ## Логи всех сервисов (follow)
	docker compose -f clickhouse/docker-compose.yml -f signoz/docker-compose.yml logs -f

ps: ## Статус всех контейнеров
	@echo "\n\033[36m=== ClickHouse ===\033[0m"
	@docker compose -f clickhouse/docker-compose.yml ps
	@echo "\n\033[36m=== SigNoz ===\033[0m"
	@docker compose -f signoz/docker-compose.yml ps

env: ## Создать .env из .env.example (если не существует)
	@test -f signoz/.env || (cp signoz/.env.example signoz/.env && echo "Создан signoz/.env из .env.example")

