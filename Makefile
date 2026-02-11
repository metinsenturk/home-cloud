# Essential Makefile for Self-Hosted Modular Infrastructure

# Usage:
#   make create-network   # Creates the home_network if it doesn't exist

#   make up-base         # Launches base services (Traefik, etc.)

NETWORK_NAME=home_network

BASE_COMPOSE=docker compose --env-file .env -f base/docker-compose.yml

.PHONY: create-network
create-network:
	@if docker network inspect $(NETWORK_NAME) > /dev/null 2>&1; then \
		 echo "Network '$(NETWORK_NAME)' already exists."; \
	else \
		docker network create $(NETWORK_NAME); \
		echo "Network '$(NETWORK_NAME)' created."; \
	fi

# =============================================================
# Base Services
# =============================================================

.PHONY: up-base
up-base: create-network
	$(BASE_COMPOSE) up -d
	@echo "Base services launched."

.PHONY: down-base
down-base:
	$(BASE_COMPOSE) down
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


# =============================================================
# Aggregate Commands
# =============================================================

.PHONY: up-all
up-all: up-base up-infisical up-beszel up-netdata up-metabase
	@echo "All services launched."

.PHONY: down-all
down-all: down-metabase down-netdata down-beszel down-infisical down-base
	@echo "All services stopped."
