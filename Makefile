# Essential Makefile for Self-Hosted Modular Infrastructure

# Usage:
#   make create-network              # Creates the home_network if it doesn't exist
#   make check-validity APP=app_name # Validates a compose file for an app
#   make up-base                     # Launches base services (Traefik, Dozzle, WUD)
#   make up-all                      # Launches all services

NETWORK_NAME=home_network

.PHONY: create-network
create-network:
	@if docker network inspect $(NETWORK_NAME) > /dev/null 2>&1; then \
		 echo "Network '$(NETWORK_NAME)' already exists."; \
	else \
		docker network create $(NETWORK_NAME); \
		echo "Network '$(NETWORK_NAME)' created."; \
	fi

# =============================================================
# Utilities
# =============================================================

.PHONY: check-validity
check-validity:
	@if [ -z "$(APP)" ]; then \
		echo "Usage: make check-validity APP=app_name"; \
		echo "Example: make check-validity APP=traefik"; \
		exit 1; \
	fi
	@if [ ! -f "apps/$(APP)/docker-compose.yml" ]; then \
		echo "✗ Error: apps/$(APP)/docker-compose.yml not found"; \
		exit 1; \
	fi
	@docker compose -f apps/$(APP)/docker-compose.yml config > /dev/null 2>&1 && \
		echo "✓ $(APP) compose file is valid" || \
		(echo "✗ $(APP) compose file is invalid" && exit 1)

# =============================================================
# Base Services (Traefik, Dozzle, WUD)
# =============================================================

.PHONY: up-traefik
up-traefik: create-network
	docker compose \
		--env-file .env \
		-f apps/traefik/docker-compose.yml up -d

.PHONY: down-traefik
down-traefik:
	docker compose \
		--env-file .env \
		-f apps/traefik/docker-compose.yml down

.PHONY: up-dozzle
up-dozzle: create-network
	docker compose \
		--env-file .env \
		-f apps/dozzle/docker-compose.yml up -d

.PHONY: down-dozzle
down-dozzle:
	docker compose \
		--env-file .env \
		-f apps/dozzle/docker-compose.yml down

.PHONY: up-wud
up-wud: create-network
	docker compose \
		--env-file .env \
		-f apps/wud/docker-compose.yml up -d

.PHONY: down-wud
down-wud:
	docker compose \
		--env-file .env \
		-f apps/wud/docker-compose.yml down

.PHONY: up-base
up-base: up-traefik up-dozzle up-wud
	@echo "Base services launched."

.PHONY: down-base
down-base: down-dozzle down-wud down-traefik
	@echo "Base services stopped."

.PHONY: recreate-base
recreate-base: down-base up-base
	@echo "Base services recreated."

# =============================================================
# Apps
# =============================================================

.PHONY: up-infisical
up-infisical: create-network
	docker compose \
		--env-file .env \
		--env-file apps/infisical/.env \
		-f apps/infisical/docker-compose.yml up -d

.PHONY: down-infisical
down-infisical:
	docker compose \
		--env-file .env \
		--env-file apps/infisical/.env \
		-f apps/infisical/docker-compose.yml down

.PHONY: up-beszel
up-beszel: create-network
	docker compose \
		--env-file .env \
		--env-file apps/beszel/.env \
		-f apps/beszel/docker-compose.yml up -d

.PHONY: down-beszel
down-beszel:
	docker compose \
		--env-file .env \
		--env-file apps/beszel/.env \
		-f apps/beszel/docker-compose.yml down

.PHONY: up-coder
up-coder: create-network
	docker compose \
		--env-file .env \
		--env-file apps/coder/.env \
		-f apps/coder/docker-compose.yml up -d

.PHONY: down-coder
down-coder:
	docker compose \
		--env-file .env \
		--env-file apps/coder/.env \
		-f apps/coder/docker-compose.yml down

.PHONY: up-netdata
up-netdata: create-network
	docker compose \
		--env-file .env \
		--env-file apps/netdata/.env \
		-f apps/netdata/docker-compose.yml up -d

.PHONY: down-netdata
down-netdata:
	docker compose \
		--env-file .env \
		--env-file apps/netdata/.env \
		-f apps/netdata/docker-compose.yml down

.PHONY: up-metabase
up-metabase: create-network
	docker compose \
		--env-file .env \
		--env-file apps/metabase/.env \
		-f apps/metabase/docker-compose.yml up -d

.PHONY: down-metabase
down-metabase:
	docker compose \
		--env-file .env \
		--env-file apps/metabase/.env \
		-f apps/metabase/docker-compose.yml down

.PHONY: up-nocodb
up-nocodb: create-network
	docker compose \
		--env-file .env \
		--env-file apps/nocodb/.env \
		-f apps/nocodb/docker-compose.yml up -d

.PHONY: down-nocodb
down-nocodb:
	docker compose \
		--env-file .env \
		--env-file apps/nocodb/.env \
		-f apps/nocodb/docker-compose.yml down

.PHONY: up-glance
up-glance: create-network
	docker compose \
		--env-file .env \
		--env-file apps/glance/.env \
		-f apps/glance/docker-compose.yml up -d

.PHONY: down-glance
down-glance:
	docker compose \
		--env-file .env \
		--env-file apps/glance/.env \
		-f apps/glance/docker-compose.yml down

.PHONY: up-jupyter
up-jupyter: create-network
	docker compose \
		--env-file .env \
		--env-file apps/jupyter/.env \
		-f apps/jupyter/docker-compose.yml up -d

.PHONY: down-jupyter
down-jupyter:
	docker compose \
		--env-file .env \
		--env-file apps/jupyter/.env \
		-f apps/jupyter/docker-compose.yml down

.PHONY: up-marimo
up-marimo: create-network
	docker compose \
		--env-file .env \
		--env-file apps/marimo/.env \
		-f apps/marimo/docker-compose.yml up -d

.PHONY: down-marimo
down-marimo:
	docker compose \
		--env-file .env \
		--env-file apps/marimo/.env \
		-f apps/marimo/docker-compose.yml down

.PHONY: up-pgadmin
up-pgadmin: create-network
	docker compose \
		--env-file .env \
		--env-file apps/pgadmin/.env \
		-f apps/pgadmin/docker-compose.yml up -d

.PHONY: down-pgadmin
down-pgadmin:
	docker compose \
		--env-file .env \
		--env-file apps/pgadmin/.env \
		-f apps/pgadmin/docker-compose.yml down

.PHONY: up-pgbackweb
up-pgbackweb: create-network
	docker compose \
		--env-file .env \
		--env-file apps/pgbackweb/.env \
		-f apps/pgbackweb/docker-compose.yml up -d

.PHONY: down-pgbackweb
down-pgbackweb:
	docker compose \
		--env-file .env \
		--env-file apps/pgbackweb/.env \
		-f apps/pgbackweb/docker-compose.yml down

.PHONY: up-infra-postgres
up-infra-postgres: create-network
	docker compose \
		--env-file .env \
		--env-file apps/infra_postgres/.env \
		-f apps/infra_postgres/docker-compose.yml up -d

.PHONY: down-infra-postgres
down-infra-postgres:
	docker compose \
		--env-file .env \
		--env-file apps/infra_postgres/.env \
		-f apps/infra_postgres/docker-compose.yml down

.PHONY: up-infra-mssql
up-infra-mssql: create-network
	docker compose \
		--env-file .env \
		--env-file apps/infra_mssql/.env \
		-f apps/infra_mssql/docker-compose.yml up -d

.PHONY: down-infra-mssql
down-infra-mssql:
	docker compose \
		--env-file .env \
		--env-file apps/infra_mssql/.env \
		-f apps/infra_mssql/docker-compose.yml down

.PHONY: up-infra-mongodb
up-infra-mongodb: create-network
	docker compose \
		--env-file .env \
		--env-file apps/infra_mongodb/.env \
		-f apps/infra_mongodb/docker-compose.yml up -d

.PHONY: down-infra-mongodb
down-infra-mongodb:
	docker compose \
		--env-file .env \
		--env-file apps/infra_mongodb/.env \
		-f apps/infra_mongodb/docker-compose.yml down

.PHONY: up-mage
up-mage: create-network
	docker compose \
		--env-file .env \
		--env-file apps/mage/.env \
		-f apps/mage/docker-compose.yml up -d

.PHONY: down-mage
down-mage:
	docker compose \
		--env-file .env \
		--env-file apps/mage/.env \
		-f apps/mage/docker-compose.yml down

.PHONY: up-memos
up-memos: create-network
	docker compose \
		--env-file .env \
		--env-file apps/memos/.env \
		-f apps/memos/docker-compose.yml up -d

.PHONY: down-memos
down-memos:
	docker compose \
		--env-file .env \
		--env-file apps/memos/.env \
		-f apps/memos/docker-compose.yml down

.PHONY: up-mailpit
up-mailpit: create-network
	docker compose \
		--env-file .env \
		--env-file apps/mailpit/.env \
		-f apps/mailpit/docker-compose.yml up -d

.PHONY: down-mailpit
down-mailpit:
	docker compose \
		--env-file .env \
		--env-file apps/mailpit/.env \
		-f apps/mailpit/docker-compose.yml down

.PHONY: up-portracker
up-portracker: create-network
	docker compose \
		--env-file .env \
		--env-file apps/portracker/.env \
		-f apps/portracker/docker-compose.yml up -d

.PHONY: down-portracker
down-portracker:
	docker compose \
		--env-file .env \
		--env-file apps/portracker/.env \
		-f apps/portracker/docker-compose.yml down

.PHONY: up-gitlab
up-gitlab: create-network
	docker compose \
		--env-file .env \
		--env-file apps/gitlab/.env \
		-f apps/gitlab/docker-compose.yml up -d

.PHONY: down-gitlab
down-gitlab:
	docker compose \
		--env-file .env \
		--env-file apps/gitlab/.env \
		-f apps/gitlab/docker-compose.yml down

.PHONY: up-redash
up-redash: create-network
	docker compose \
		--env-file .env \
		--env-file apps/redash/.env \
		-f apps/redash/docker-compose.yml up -d

.PHONY: down-redash
down-redash:
	docker compose \
		--env-file .env \
		--env-file apps/redash/.env \
		-f apps/redash/docker-compose.yml down

.PHONY: up-vscode
up-vscode: create-network
	docker compose \
		--env-file .env \
		--env-file apps/vscode/.env \
		-f apps/vscode/docker-compose.yml up -d

.PHONY: down-vscode
down-vscode:
	docker compose \
		--env-file .env \
		--env-file apps/vscode/.env \
		-f apps/vscode/docker-compose.yml down

.PHONY: up-openclaw
up-openclaw: create-network
	docker compose \
		--env-file .env \
		--env-file apps/openclaw/.env \
		-f apps/openclaw/docker-compose.yml up -d

.PHONY: down-openclaw
down-openclaw:
	docker compose \
		--env-file .env \
		--env-file apps/openclaw/.env \
		-f apps/openclaw/docker-compose.yml down

.PHONY: up-uptime-kuma
up-uptime-kuma: create-network
	docker compose \
		--env-file .env \
		--env-file apps/uptime-kuma/.env \
		-f apps/uptime-kuma/docker-compose.yml up -d

.PHONY: down-uptime-kuma
down-uptime-kuma:
	docker compose \
		--env-file .env \
		--env-file apps/uptime-kuma/.env \
		-f apps/uptime-kuma/docker-compose.yml down

.PHONY: up-resume
up-resume: create-network
	docker compose \
		--env-file .env \
		--env-file apps/resume/.env \
		-f apps/resume/docker-compose.yml up -d

.PHONY: down-resume
down-resume:
	docker compose \
		--env-file .env \
		--env-file apps/resume/.env \
		-f apps/resume/docker-compose.yml down


# =============================================================
# Aggregate Commands
# =============================================================

.PHONY: up-all
up-all: up-traefik up-dozzle up-wud up-infra-postgres up-infra-mssql up-infra-mongodb up-infisical up-beszel up-coder up-netdata up-metabase up-nocodb up-glance up-jupyter up-marimo up-mage up-memos up-mailpit up-portracker up-gitlab up-pgadmin up-pgbackweb up-redash up-vscode up-openclaw up-uptime-kuma up-resume
	@echo "All services launched."

.PHONY: down-all
down-all: down-resume down-uptime-kuma down-openclaw down-vscode down-redash down-pgbackweb down-pgadmin down-gitlab down-portracker down-mailpit down-memos down-mage down-marimo down-jupyter down-glance down-nocodb down-metabase down-netdata down-coder down-beszel down-infisical down-infra-mongodb down-infra-mssql down-infra-postgres down-wud down-dozzle down-traefik
	@echo "All services stopped."
