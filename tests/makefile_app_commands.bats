#!/usr/bin/env bats

# Makefile per-app command construction tests.
#
# These tests assert docker compose argument wiring for representative targets.
# They do not start real containers; assertions read the mocked docker log.
#
# Test Organization:
# - Split into two categories: simple compose and multi-file compose
# - Simple: Single compose file with standard env-file patterns
# - Multi-file: Multiple compose files or additional flags (--build)
#
# This split improves failure localization and makes it clear which patterns
# are being validated (basic orchestration vs. complex layering).
#
# Pattern:
# - Table-driven cases keep coverage compact and easy to extend
# - Add a new row to the appropriate table to cover another target
# - Format: target_name|expected_docker_arguments
#
# IMPORTANT - Tab Format:
# The expected_docker_arguments use TAB characters (not spaces) between each
# argument because the mock docker script logs with tab separators. This looks
# odd in the editor but is necessary for exact match validation.
# 
# Example breakdown of a table row:
#   up-blinko|docker<TAB>compose<TAB>--env-file<TAB>.env<TAB>...
#   
# When reading the file, each argument after the pipe is separated by tabs.

load test_helper

# Helper function to validate docker compose invocations.
# - Executes a make target
# - Compares actual docker log against expected tab-separated argv
# - Provides clear failure messages with diff output
run_and_assert_compose_line() {
  local target="$1"
  local expected_line="$2"

  reset_docker_log
  run make_in_tmp "$target"

  if [ "$status" -ne 0 ]; then
    echo "Target failed: $target"
    echo "$output"
    return 1
  fi

  if ! docker_log_contains "$expected_line"; then
    echo "Expected docker invocation not found for target: $target"
    echo "Expected:"
    echo "$expected_line"
    echo "Actual docker log:"
    cat "$MOCK_DOCKER_LOG_FILE"
    return 1
  fi
}

# ==============================================================================
# Simple Compose Targets
# ==============================================================================
# These targets use a single docker-compose.yml file with standard env vars.
# They are the most common pattern in the infrastructure.
#
# Table format: target|expected_docker_argv
# - target: the make target to test (e.g., up-blinko)
# - expected_docker_argv: tab-separated arguments from mock docker log
#
# Each row validates:
# - Correct env-file loading order (.env first, then app .env if present)
# - Correct compose file path resolution
# - Correct compose command (up -d, down, etc.)
#
# Note: The pipe-separated values after target use TABS (not spaces) to match
# the mock docker log format. This is intentional, though it looks odd in the editor.
#
# Examples explained:
# - up-traefik: Root .env only (base infrastructure, no app-specific .env)
# - up-dozzle/up-wud: Root .env only (monitoring services)
# - down-dozzle: Same pattern but with down command
# - up-blinko/up-beszel: Root .env + app .env (standard pattern for most apps)
# - down-blinko/down-beszel: Same env loading, different command
# - up-infra-*: Infrastructure services (postgres, mssql, mongodb) with app-specific env
# - up-coder/up-metabase/up-gitlab: Various application types with standard pattern

@test "simple compose targets build expected docker compose commands" {
  while IFS='|' read -r target expected_line; do
    run_and_assert_compose_line "$target" "$expected_line"
  done <<'EOF'
up-traefik|docker	compose	--env-file	.env	-f	apps/traefik/docker-compose.yml	up	-d
up-dozzle|docker	compose	--env-file	.env	-f	apps/dozzle/docker-compose.yml	up	-d
down-dozzle|docker	compose	--env-file	.env	-f	apps/dozzle/docker-compose.yml	down
up-wud|docker	compose	--env-file	.env	-f	apps/wud/docker-compose.yml	up	-d
up-blinko|docker	compose	--env-file	.env	--env-file	apps/blinko/.env	-f	apps/blinko/docker-compose.yml	up	-d
down-blinko|docker	compose	--env-file	.env	--env-file	apps/blinko/.env	-f	apps/blinko/docker-compose.yml	down
up-beszel|docker	compose	--env-file	.env	--env-file	apps/beszel/.env	-f	apps/beszel/docker-compose.yml	up	-d
down-beszel|docker	compose	--env-file	.env	--env-file	apps/beszel/.env	-f	apps/beszel/docker-compose.yml	down
up-infra-postgres|docker	compose	--env-file	.env	--env-file	apps/infra_postgres/.env	-f	apps/infra_postgres/docker-compose.yml	up	-d
up-infra-mssql|docker	compose	--env-file	.env	--env-file	apps/infra_mssql/.env	-f	apps/infra_mssql/docker-compose.yml	up	-d
down-infra-mssql|docker	compose	--env-file	.env	--env-file	apps/infra_mssql/.env	-f	apps/infra_mssql/docker-compose.yml	down
up-infra-mongodb|docker	compose	--env-file	.env	--env-file	apps/infra_mongodb/.env	-f	apps/infra_mongodb/docker-compose.yml	up	-d
up-coder|docker	compose	--env-file	.env	--env-file	apps/coder/.env	-f	apps/coder/docker-compose.yml	up	-d
up-metabase|docker	compose	--env-file	.env	--env-file	apps/metabase/.env	-f	apps/metabase/docker-compose.yml	up	-d
up-gitlab|docker	compose	--env-file	.env	--env-file	apps/gitlab/.env	-f	apps/gitlab/docker-compose.yml	up	-d
EOF
}

# ==============================================================================
# Multi-File Compose Targets
# ==============================================================================
# These targets involve multiple compose files or additional flags (--build).
# They represent more complex patterns like:
# - Overlay compose files (e.g., freqtrade with postgres backend)
# - Build targets with custom flags
#
# Table format: target|expected_docker_argv
# - Multiple -f flags indicate compose file layering (base file, then overlays)
# - --build flag indicates custom image building during up
# - --no-cache ensures clean builds without layer caching
# - Order matters: base compose file first, then override/extension files
#
# Note: The pipe-separated values use TABS (not spaces) to match the mock docker
# log format. Visual alignment is sacrificed for exact match validation.
#
# Examples explained:
# - up-freqtrade: Single compose file variant (baseline for comparison)
# - down-freqtrade: Same baseline with down command
# - up-freqtrade-postgres: Two compose files (base + postgres overlay) with --build flag
# - down-freqtrade-postgres: Same multi-file structure with down (no build needed)
# - build-freqtrade: Explicit build command with --no-cache for clean image rebuilds

@test "multi-file compose targets build expected docker compose commands" {
  while IFS='|' read -r target expected_line; do
    run_and_assert_compose_line "$target" "$expected_line"
  done <<'EOF'
up-freqtrade|docker	compose	--env-file	.env	--env-file	apps/freqtrade/.env	-f	apps/freqtrade/docker-compose.yml	up	-d
down-freqtrade|docker	compose	--env-file	.env	--env-file	apps/freqtrade/.env	-f	apps/freqtrade/docker-compose.yml	down
up-freqtrade-postgres|docker	compose	--env-file	.env	--env-file	apps/freqtrade/.env	-f	apps/freqtrade/docker-compose.yml	-f	apps/freqtrade/docker-compose.postgres.yml	up	-d	--build
down-freqtrade-postgres|docker	compose	--env-file	.env	--env-file	apps/freqtrade/.env	-f	apps/freqtrade/docker-compose.yml	-f	apps/freqtrade/docker-compose.postgres.yml	down
build-freqtrade|docker	compose	--env-file	.env	--env-file	apps/freqtrade/.env	-f	apps/freqtrade/docker-compose.yml	-f	apps/freqtrade/docker-compose.postgres.yml	build	--no-cache
EOF
}

# ==============================================================================
# Logging & Management Commands
# ==============================================================================
# These are pattern-rule commands that work for any app.
#
# logs-<appname>: View live logs from an app's containers
# - Uses pattern rule logs-% to match any app name
# - Conditionally loads app-specific .env only if it exists
# - Shows last 50 lines with timestamps and follows in real-time
# - Works with multi-container apps (shows all containers' logs)
#
# ps: Show status of all running containers
# - Simple global command that shows status across all services
#
# Note: Core services (dozzle, traefik, wud) don't have .env files,
# so logs-% uses different commands based on file existence.
#
# Table format: target|expected_docker_argv

@test "logging and management targets build expected docker compose commands" {
  while IFS='|' read -r target expected_line; do
    run_and_assert_compose_line "$target" "$expected_line"
  done <<'EOF'
logs-blinko|docker	compose	--env-file	.env	-f	apps/blinko/docker-compose.yml	logs	-f	--tail=50	--timestamps
logs-metabase|docker	compose	--env-file	.env	-f	apps/metabase/docker-compose.yml	logs	-f	--tail=50	--timestamps
logs-infra_postgres|docker	compose	--env-file	.env	-f	apps/infra_postgres/docker-compose.yml	logs	-f	--tail=50	--timestamps
logs-dozzle|docker	compose	--env-file	.env	-f	apps/dozzle/docker-compose.yml	logs	-f	--tail=50	--timestamps
ps|docker	compose	ps
EOF
}
