# Essential Makefile for Self-Hosted Modular Infrastructure
#
# Overview:
#   This Makefile orchestrates a modular Docker Compose-based infrastructure
#   where each application lives in its own directory under apps/ and can be
#   launched independently or in custom groups.
#
# Requirements:
#   - GNU Make (3.81+)
#   - Docker Engine (20.10+)
#   - Docker Compose v2 (docker compose, not docker-compose)
#   - bash shell (for command execution)
#   - yq (optional, required only for GROUPS_BACKEND=yaml)
#   - bats-core (optional, required only for make test-makefile)
#
# Command Language:
#   All commands use bash shell syntax. The Makefile recipes execute
#   shell scripts with conditionals, loops, and Docker Compose commands.
#
# Environment:
#   - All apps require a root .env file and an app-specific .env file
#   - Variables from root .env are loaded first, then app .env overrides
#   - The docker compose --env-file flag is used for variable injection
#
# Network Architecture:
#   - All services connect to an external bridge network: home_network
#   - Traefik (reverse proxy) routes traffic based on subdomain labels
#   - Apps define their own internal networks when needed
#
# Working Directory:
#   ALL make commands MUST be run from the repository root directory.
#   The Makefile expects the following structure:
#     .
#     ├── Makefile          (this file)
#     ├── .env              (root environment variables)
#     ├── apps/             (application directories)
#     │   ├── traefik/
#     │   ├── blinko/
#     │   └── ...
#     ├── groups.mk         (optional, custom app groups)
#     └── groups.yaml       (optional, custom app groups)
#
#   Example:
#     cd /path/to/home-cloud    # Navigate to repository root
#     make up-base              # Run commands from here
#
#
# Quick Start:
#   1. Ensure Docker and Docker Compose are installed
#   2. Create .env files (see .env.example)
#   3. Run: make create-network
#   4. Run: make up-base (starts Traefik, Dozzle, WUD)
#   5. Run: make up-<appname> to launch individual apps
#   6. Optional: make init-groups to enable custom app grouping
#
# Usage:
#   make create-network              # Creates the home_network if it doesn't exist
#   make init-env                    # Creates root .env from .env.example (one-time setup)
#   make install-optional-tools      # Installs optional dependencies (bats, GNU parallel, yq, git)
#   make check-validity APP=app_name # Validates a compose file for an app
#   make check-tools                 # Checks for required and optional dependencies
#   make up-base                     # Launches base services (Traefik, Dozzle, WUD)
#   make up-all                      # Launches all services
#   make logs-<appname>              # View live logs for an app (e.g., make logs-dozzle)
#   make ps                          # Show status of all running containers
#   make test-makefile               # Runs unit-like tests for Makefile commands
#   make test-makefile-integration   # Runs integration tests (quick tier, ~30-60s)
#   make test-makefile-integration-quick  # Explicit quick tier: network, compose validation
#   make test-makefile-integration-full   # Full tier: app lifecycle tests (3-5 minutes)
#   make test-makefile-all           # Runs unit + integration (quick tier by default)
#   make list-groups                 # Lists available custom app groups
#   make init-groups                 # Creates group config file from example
#   make clean-groups                # Removes group config file
#   make up-group-favorites          # Launches apps from a custom group
#   make down-group-favorites        # Stops apps from a custom group
#   make up-favorites                # Shortcut alias for up-group-favorites
#   make down-favorites              # Shortcut alias for down-group-favorites
#
# Custom group backends:
#   GROUPS_BACKEND=make (default, no dependency)
#     - Reads groups from GROUPS_MAKE_FILE (default: groups.mk)
#     - Expects:
#         GROUPS := favorites finance
#         GROUP_favorites := blinko glance
#         GROUP_finance := freqtrade metabase
#
#   GROUPS_BACKEND=yaml (requires yq)
#     - Reads groups from GROUPS_YAML_FILE (default: groups.yaml)
#     - Expects:
#         groups:
#           favorites: [blinko, glance]
#           finance: [freqtrade, metabase]
#
# Examples:
#   make init-groups                 # Create groups.mk from example
#   make list-groups                 # List available groups
#   make up-group-favorites          # Start favorites group
#   make down-group-favorites        # Stop favorites group
#   make clean-groups                # Remove groups.mk
#   make init-groups GROUPS_BACKEND=yaml        # Create groups.yaml
#   make list-groups GROUPS_BACKEND=yaml        # List groups (YAML mode)
#   make clean-groups GROUPS_BACKEND=yaml       # Remove groups.yaml

NETWORK_NAME=home_network

# Supported values: make | yaml
# - make: dependency-free mode using a Make include file
# - yaml: YAML mode parsed by yq
#
# Resolution order:
#   1) Command line: GROUPS_BACKEND=yaml make list-groups
#   2) Process environment: export GROUPS_BACKEND=yaml
#   3) Root .env: HOME_CLOUD_GROUPS_BACKEND=yaml
#   4) Fallback default: make
GROUPS_BACKEND_FROM_ENV:=$(strip $(shell sed -n 's/^HOME_CLOUD_GROUPS_BACKEND[[:space:]]*=[[:space:]]*//p' .env 2>/dev/null | sed 's/[[:space:]]*#.*$$//' | tr '[:upper:]' '[:lower:]' | head -n1))
GROUPS_BACKEND?=$(if $(GROUPS_BACKEND_FROM_ENV),$(GROUPS_BACKEND_FROM_ENV),make)

# Path to YAML group config (used only when GROUPS_BACKEND=yaml)
GROUPS_YAML_FILE?=groups.yaml

# Path to Make group config (used only when GROUPS_BACKEND=make)
GROUPS_MAKE_FILE?=groups.mk

# Optional include so Make backend works when groups.mk is present.
# If file is missing, list/execute group targets will return a clear error.
# Using `-` to prevent Make from erroring out if the file doesn't exist, since it's optional.
-include $(GROUPS_MAKE_FILE)

# Group names in commands use dashes (up-group-home-lab), while Make
# variable names commonly use underscores (GROUP_home_lab). This helper
# maps dashes to underscores before looking up the group variable.
get_make_group_apps = $(strip $(value GROUP_$(subst -,_,$(1))))

.PHONY: check-tools
check-tools:
	@# Checks for required and optional tools used by this project
	@echo "Checking dependencies for Mini-Cloud infrastructure..."
	@echo ""
	@echo "=== REQUIRED Tools ==="
	@command -v docker > /dev/null && echo "✓ docker" || echo "✗ docker (MISSING)"
	@command -v docker compose > /dev/null && echo "✓ docker compose" || echo "✗ docker compose (MISSING)"
	@command -v make > /dev/null && echo "✓ make" || echo "✗ make (MISSING)"
	@command -v bash > /dev/null && echo "✓ bash" || echo "✗ bash (MISSING)"
	@echo ""
	@echo "=== OPTIONAL Tools ==="
	@if command -v bats > /dev/null 2>&1; then \
		echo "✓ bats (testing: make test-makefile)"; \
	else \
		echo "✗ bats (optional, for: make test-makefile)"; \
	fi
	@if command -v parallel > /dev/null 2>&1; then \
		echo "✓ GNU parallel (testing: parallel execution with BATS_PARALLEL=1)"; \
	else \
		echo "✗ GNU parallel (optional, for parallel test execution)"; \
	fi
	@if command -v yq > /dev/null 2>&1; then \
		echo "✓ yq (optional, for: GROUPS_BACKEND=yaml)"; \
	else \
		echo "✗ yq (optional, for YAML group backend)"; \
	fi
	@if command -v git > /dev/null 2>&1; then \
		echo "✓ git (optional, for repository management)"; \
	else \
		echo "✗ git (optional, for repository management)"; \
	fi
	@echo ""
	@echo "Tip: Install missing tools with: sudo apt-get install <tool>"

.PHONY: install-optional-tools
install-optional-tools:
	@# Installs optional tooling for testing and group backends.
	@# Supported package managers: apt-get (Ubuntu/WSL), brew (macOS).
	@set -e; \
	if command -v apt-get > /dev/null 2>&1; then \
		echo "Detected apt-get. Installing optional tools: bats, GNU parallel, yq, git"; \
		sudo apt-get update; \
		sudo apt-get install -y bats parallel yq git; \
	elif command -v brew > /dev/null 2>&1; then \
		echo "Detected Homebrew. Installing optional tools: bats-core, GNU parallel, yq, git"; \
		brew install bats-core parallel yq git; \
	else \
		echo "✗ Error: unsupported package manager."; \
		echo "  Install optional tools manually: bats, parallel, yq, git"; \
		exit 1; \
	fi
	@echo "✓ Optional tools installation complete."
	@$(MAKE) check-tools

.PHONY: create-network
create-network:
	@if docker network inspect $(NETWORK_NAME) > /dev/null 2>&1; then \
		 echo "Network '$(NETWORK_NAME)' already exists."; \
	else \
		docker network create $(NETWORK_NAME); \
		echo "Network '$(NETWORK_NAME)' created."; \
	fi

.PHONY: init-env
init-env:
	@# Creates root .env from .env.example for first-time setup.
	@# Fails if .env already exists to avoid accidental overwrite of secrets.
	@if [ -f ".env" ]; then \
		echo "✗ Error: .env already exists"; \
		exit 1; \
	fi
	@if [ ! -f ".env.example" ]; then \
		echo "✗ Error: .env.example not found"; \
		exit 1; \
	fi
	@cp .env.example .env
	@echo "✓ Created .env from .env.example"

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

.PHONY: test-makefile
test-makefile:
	@# Runs unit-like Makefile tests using bats and local mocks.
	@if ! command -v bats > /dev/null 2>&1; then \
		echo "✗ Error: bats is required. Install bats-core to run tests."; \
		echo "  Ubuntu/WSL: sudo apt-get install -y bats"; \
		exit 1; \
	fi
	@BATS_JOBS=$$([ "$(BATS_PARALLEL)" = "1" ] && echo "--jobs 4" || echo ""); \
	bats $$BATS_JOBS tests/*.bats

.PHONY: test-makefile-integration
test-makefile-integration: test-makefile-integration-quick
	@# Integration tests default to quick tier for fast feedback.
	@# Use 'make test-makefile-integration-full' for deep lifecycle tests.

.PHONY: test-makefile-integration-quick
test-makefile-integration-quick:
	@# Quick sanity checks (check-validity, network creation)
	@# Runtime: ~30-60 seconds total
	@if ! command -v bats > /dev/null 2>&1; then \
		echo "✗ Error: bats is required. Install bats-core to run tests."; \
		echo "  Ubuntu/WSL: sudo apt-get install -y bats"; \
		exit 1; \
	fi
	@if [ "$(RUN_INTEGRATION)" != "1" ]; then \
		echo "✗ Error: integration tests are opt-in."; \
		echo "  Run: make test-makefile-integration-quick RUN_INTEGRATION=1"; \
		exit 1; \
	fi
	@BATS_JOBS=$$([ "$(BATS_PARALLEL)" = "1" ] && echo "--jobs 2" || echo ""); \
	RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=quick bats $$BATS_JOBS tests/integration/*.bats

.PHONY: test-makefile-integration-full
test-makefile-integration-full:
	@# Full integration testing including app lifecycle (startup, healthcheck, teardown)
	@# Runtime: 3-5 minutes depending on system and container startup times
	@if ! command -v bats > /dev/null 2>&1; then \
		echo "✗ Error: bats is required. Install bats-core to run tests."; \
		echo "  Ubuntu/WSL: sudo apt-get install -y bats"; \
		exit 1; \
	fi
	@if [ "$(RUN_INTEGRATION)" != "1" ]; then \
		echo "✗ Error: integration tests are opt-in."; \
		echo "  Run: make test-makefile-integration-full RUN_INTEGRATION=1"; \
		exit 1; \
	fi
	@BATS_JOBS=$$([ "$(BATS_PARALLEL)" = "1" ] && echo "--jobs 2" || echo ""); \
	RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=full bats $$BATS_JOBS tests/integration/*.bats

.PHONY: test-makefile-all
test-makefile-all: test-makefile
	@# Runs all test layers. Integration remains opt-in for safety.
	@if [ "$(RUN_INTEGRATION)" = "1" ]; then \
		$(MAKE) test-makefile-integration RUN_INTEGRATION=1; \
	else \
		echo "Skipping integration tests (set RUN_INTEGRATION=1 to enable)."; \
	fi

.PHONY: init-groups
init-groups:
	@# Creates a group config file from the example template.
	@# Fails if the target file already exists to prevent accidental overwrites.
	@case "$(GROUPS_BACKEND)" in \
		yaml) \
			if [ -f "$(GROUPS_YAML_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE) already exists"; \
				exit 1; \
			fi; \
			if [ ! -f "$(GROUPS_YAML_FILE).example" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE).example not found"; \
				exit 1; \
			fi; \
			cp "$(GROUPS_YAML_FILE).example" "$(GROUPS_YAML_FILE)"; \
			echo "✓ Created $(GROUPS_YAML_FILE) from example"; \
			;; \
		make) \
			if [ -f "$(GROUPS_MAKE_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_MAKE_FILE) already exists"; \
				exit 1; \
			fi; \
			if [ ! -f "$(GROUPS_MAKE_FILE).example" ]; then \
				echo "✗ Error: $(GROUPS_MAKE_FILE).example not found"; \
				exit 1; \
			fi; \
			cp "$(GROUPS_MAKE_FILE).example" "$(GROUPS_MAKE_FILE)"; \
			echo "✓ Created $(GROUPS_MAKE_FILE) from example"; \
			;; \
		*) \
			echo "✗ Error: invalid GROUPS_BACKEND='$(GROUPS_BACKEND)' (use 'make' or 'yaml')"; \
			exit 1; \
			;; \
	esac

.PHONY: clean-groups
clean-groups:
	@# Removes the active group config file.
	@# Fails if the file doesn't exist to prevent silent failures.
	@case "$(GROUPS_BACKEND)" in \
		yaml) \
			if [ ! -f "$(GROUPS_YAML_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE) not found"; \
				exit 1; \
			fi; \
			rm "$(GROUPS_YAML_FILE)"; \
			echo "✓ Removed $(GROUPS_YAML_FILE)"; \
			;; \
		make) \
			if [ ! -f "$(GROUPS_MAKE_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_MAKE_FILE) not found"; \
				exit 1; \
			fi; \
			rm "$(GROUPS_MAKE_FILE)"; \
			echo "✓ Removed $(GROUPS_MAKE_FILE)"; \
			;; \
		*) \
			echo "✗ Error: invalid GROUPS_BACKEND='$(GROUPS_BACKEND)' (use 'make' or 'yaml')"; \
			exit 1; \
			;; \
	esac

.PHONY: list-groups
list-groups:
	@# Lists user-defined group names from the selected backend.
	@case "$(GROUPS_BACKEND)" in \
		yaml) \
			if ! command -v yq > /dev/null 2>&1; then \
				echo "✗ Error: yq is required for GROUPS_BACKEND=yaml"; \
				exit 1; \
			fi; \
			if [ ! -f "$(GROUPS_YAML_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE) not found"; \
				exit 1; \
			fi; \
			echo "Available groups ($(GROUPS_BACKEND)) from $(GROUPS_YAML_FILE):"; \
			yq -r '.groups | keys[]' "$(GROUPS_YAML_FILE)"; \
			;; \
		make) \
			if [ -z "$(strip $(GROUPS))" ]; then \
				echo "✗ Error: no groups defined in $(GROUPS_MAKE_FILE)"; \
				echo "  Define GROUPS and GROUP_<name> variables (see groups.mk.example)."; \
				exit 1; \
			fi; \
			echo "Available groups ($(GROUPS_BACKEND)) from $(GROUPS_MAKE_FILE): $(GROUPS)"; \
			;; \
		*) \
			echo "✗ Error: invalid GROUPS_BACKEND='$(GROUPS_BACKEND)' (use 'make' or 'yaml')"; \
			exit 1; \
			;; \
	esac

.PHONY: up-group-%
up-group-%:
	@# Starts all apps inside a named group, in the declared order.
	@case "$(GROUPS_BACKEND)" in \
		yaml) \
			if ! command -v yq > /dev/null 2>&1; then \
				echo "✗ Error: yq is required for GROUPS_BACKEND=yaml"; \
				exit 1; \
			fi; \
			if [ ! -f "$(GROUPS_YAML_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE) not found"; \
				exit 1; \
			fi; \
			apps=$$(yq -r '.groups["$*"][]?' "$(GROUPS_YAML_FILE)"); \
			if [ -z "$$apps" ]; then \
				echo "✗ Error: group '$*' not found or empty in $(GROUPS_YAML_FILE)"; \
				exit 1; \
			fi; \
			for app in $$apps; do \
				echo "→ Starting $$app"; \
				$(MAKE) up-$$app || exit $$?; \
			done; \
			;; \
		make) \
			apps="$(call get_make_group_apps,$*)"; \
			if [ -z "$$apps" ]; then \
				echo "✗ Error: group '$*' not found or empty in $(GROUPS_MAKE_FILE)"; \
				exit 1; \
			fi; \
			for app in $$apps; do \
				echo "→ Starting $$app"; \
				$(MAKE) up-$$app || exit $$?; \
			done; \
			;; \
		*) \
			echo "✗ Error: invalid GROUPS_BACKEND='$(GROUPS_BACKEND)' (use 'make' or 'yaml')"; \
			exit 1; \
			;; \
	esac

.PHONY: down-group-%
down-group-%:
	@# Stops all apps inside a named group, in the declared order.
	@case "$(GROUPS_BACKEND)" in \
		yaml) \
			if ! command -v yq > /dev/null 2>&1; then \
				echo "✗ Error: yq is required for GROUPS_BACKEND=yaml"; \
				exit 1; \
			fi; \
			if [ ! -f "$(GROUPS_YAML_FILE)" ]; then \
				echo "✗ Error: $(GROUPS_YAML_FILE) not found"; \
				exit 1; \
			fi; \
			apps=$$(yq -r '.groups["$*"][]?' "$(GROUPS_YAML_FILE)"); \
			if [ -z "$$apps" ]; then \
				echo "✗ Error: group '$*' not found or empty in $(GROUPS_YAML_FILE)"; \
				exit 1; \
			fi; \
			for app in $$apps; do \
				echo "→ Stopping $$app"; \
				$(MAKE) down-$$app || exit $$?; \
			done; \
			;; \
		make) \
			apps="$(call get_make_group_apps,$*)"; \
			if [ -z "$$apps" ]; then \
				echo "✗ Error: group '$*' not found or empty in $(GROUPS_MAKE_FILE)"; \
				exit 1; \
			fi; \
			for app in $$apps; do \
				echo "→ Stopping $$app"; \
				$(MAKE) down-$$app || exit $$?; \
			done; \
			;; \
		*) \
			echo "✗ Error: invalid GROUPS_BACKEND='$(GROUPS_BACKEND)' (use 'make' or 'yaml')"; \
			exit 1; \
			;; \
	esac

# =============================================================
# Group Aliases (Optional Shortcuts)
# =============================================================
# You can add convenient aliases for frequently-used groups here.
# These forward to the generic up-group-* / down-group-* targets.

.PHONY: up-favorites
up-favorites:
	@$(MAKE) up-group-favorites

.PHONY: down-favorites
down-favorites:
	@$(MAKE) down-group-favorites

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

.PHONY: up-blinko
up-blinko: create-network
	docker compose \
		--env-file .env \
		--env-file apps/blinko/.env \
		-f apps/blinko/docker-compose.yml up -d

.PHONY: down-blinko
down-blinko:
	docker compose \
		--env-file .env \
		--env-file apps/blinko/.env \
		-f apps/blinko/docker-compose.yml down

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

.PHONY: up-metasearch
up-metasearch: create-network
	docker compose \
		--env-file .env \
		--env-file apps/metasearch/.env \
		-f apps/metasearch/docker-compose.yml up -d

.PHONY: down-metasearch
down-metasearch:
	docker compose \
		--env-file .env \
		--env-file apps/metasearch/.env \
		-f apps/metasearch/docker-compose.yml down

.PHONY: up-datasette
up-datasette: create-network
	docker compose \
		--env-file .env \
		--env-file apps/datasette/.env \
		-f apps/datasette/docker-compose.yml up -d

.PHONY: down-datasette
down-datasette:
	docker compose \
		--env-file .env \
		--env-file apps/datasette/.env \
		-f apps/datasette/docker-compose.yml down

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

.PHONY: up-yopass
up-yopass: create-network
	docker compose \
		--env-file .env \
		--env-file apps/yopass/.env \
		-f apps/yopass/docker-compose.yml up -d

.PHONY: down-yopass
down-yopass:
	docker compose \
		--env-file .env \
		--env-file apps/yopass/.env \
		-f apps/yopass/docker-compose.yml down

.PHONY: up-freqtrade
up-freqtrade: create-network
	docker compose \
		--env-file .env \
		--env-file apps/freqtrade/.env \
		-f apps/freqtrade/docker-compose.yml up -d

.PHONY: down-freqtrade
down-freqtrade:
	docker compose \
		--env-file .env \
		--env-file apps/freqtrade/.env \
		-f apps/freqtrade/docker-compose.yml down

.PHONY: up-freqtrade-postgres
up-freqtrade-postgres: create-network
	docker compose \
		--env-file .env \
		--env-file apps/freqtrade/.env \
		-f apps/freqtrade/docker-compose.yml \
		-f apps/freqtrade/docker-compose.postgres.yml up -d --build

.PHONY: down-freqtrade-postgres
down-freqtrade-postgres:
	docker compose \
		--env-file .env \
		--env-file apps/freqtrade/.env \
		-f apps/freqtrade/docker-compose.yml \
		-f apps/freqtrade/docker-compose.postgres.yml down

.PHONY: build-freqtrade
build-freqtrade:
	docker compose \
		--env-file .env \
		--env-file apps/freqtrade/.env \
		-f apps/freqtrade/docker-compose.yml \
		-f apps/freqtrade/docker-compose.postgres.yml build --no-cache

# =============================================================
# Logging & Management
# =============================================================

.PHONY: logs-%
logs-%:
	@echo "📋 Showing logs for $* (last 50 lines, following)..."
	@echo "   Press Ctrl+C to stop"
	@echo ""
	@if [ -f apps/$*/.env ]; then \
		docker compose --env-file .env --env-file apps/$*/.env -f apps/$*/docker-compose.yml logs -f --tail=50 --timestamps; \
	else \
		docker compose --env-file .env -f apps/$*/docker-compose.yml logs -f --tail=50 --timestamps; \
	fi

.PHONY: ps
ps:
	@echo "📊 Running containers:"
	@echo ""
	docker compose ps

# =============================================================
# Aggregate Commands
# ============================================================= 

.PHONY: up-all
up-all: up-traefik up-dozzle up-wud up-infra-postgres up-infra-mssql up-infra-mongodb up-infisical up-beszel up-blinko up-coder up-netdata up-metabase up-nocodb up-glance up-jupyter up-marimo up-mage up-memos up-metasearch up-datasette up-mailpit up-portracker up-gitlab up-pgadmin up-pgbackweb up-redash up-vscode up-openclaw up-uptime-kuma up-resume up-yopass up-freqtrade
	@echo "All services launched."

.PHONY: down-all
down-all: down-freqtrade down-yopass down-resume down-uptime-kuma down-openclaw down-vscode down-redash down-pgbackweb down-pgadmin down-gitlab down-portracker down-mailpit down-datasette down-metasearch down-memos down-mage down-marimo down-jupyter down-glance down-nocodb down-metabase down-netdata down-coder down-blinko down-beszel down-infisical down-infra-mongodb down-infra-mssql down-infra-postgres down-wud down-dozzle down-traefik
	@echo "All services stopped."
