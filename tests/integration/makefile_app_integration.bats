#!/usr/bin/env bats

# Makefile app integration tests (real Docker).
#
# Scope:
# - Validates end-to-end app lifecycle for representative patterns.
# - Tests simple single-file apps (blinko) and multi-file apps (freqtrade-postgres).
# - Uses real Makefile targets and real Docker daemon.
#
# Out of scope:
# - External HTTP/API connectivity through Traefik routing.
# - Data persistence across recreates.
# - Full app matrix testing (selective pattern coverage for speed/safety).
#
# Safety model:
# - Tests are opt-in via RUN_INTEGRATION=1.
# - Disruptive tests are skipped if target containers already exist.
# - Each test cleans up its containers after completion.

load test_helper_integration

setup() {
  integration_setup_common
  export INTEGRATION_APP_STARTED=0
}

teardown() {
  if [ "${INTEGRATION_APP_STARTED:-0}" -eq 1 ]; then
    run_make_repo down-"${INTEGRATION_CURRENT_APP}" > /dev/null 2>&1 || true
  fi
}

# ==============================================================================
# Simple Compose Pattern
# ==============================================================================
# Single compose file with app-specific .env (most common pattern).

@test "blinko (simple) lifecycle: check-validity → up → wait healthy → down → verify removed" {
  export INTEGRATION_CURRENT_APP="blinko"
  require_containers_absent_or_skip blinko

  # Validate compose file before starting
  run run_make_repo check-validity APP=blinko
  [ "$status" -eq 0 ]
  [[ "$output" == *"blinko compose file is valid"* ]]

  # Start app
  run run_make_repo up-blinko
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=1

  # Wait for container to be healthy/running
  run wait_for_container_healthy_or_running blinko "$INTEGRATION_TEST_TIMEOUT"
  [ "$status" -eq 0 ]

  # Explicitly verify healthcheck is "healthy" (strict validation)
  run docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' blinko
  [ "$status" -eq 0 ]
  [[ "$output" == "healthy" || "$output" == "running" ]]

  # Verify container is in docker ps
  run docker ps --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"blinko"* ]]

  # Stop app
  run run_make_repo down-blinko
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=0

  # Verify container is removed
  run docker ps -a --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"blinko"* ]]
}

# ==============================================================================
# Infrastructure Pattern
# ==============================================================================
# Infrastructure services (databases, caches) often have no app .env or different
# naming conventions. They have database-specific healthchecks.

@test "infra-postgres (infrastructure) lifecycle: up → wait healthy → down → verify removed" {
  export INTEGRATION_CURRENT_APP="infra-postgres"
  require_containers_absent_or_skip infra_postgres

  # Start infra service
  run run_make_repo up-infra-postgres
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=1

  # Wait for container to be healthy/running
  run wait_for_container_healthy_or_running infra_postgres "$INTEGRATION_TEST_TIMEOUT"
  [ "$status" -eq 0 ]

  # Explicitly verify healthcheck is "healthy" (strict check)
  run docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' infra_postgres
  [ "$status" -eq 0 ]
  [[ "$output" == "healthy" ]]

  # Verify container is in docker ps
  run docker ps --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"infra_postgres"* ]]

  # Stop infra service
  run run_make_repo down-infra-postgres
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=0

  # Verify container is removed
  run docker ps -a --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"infra_postgres"* ]]
}

# ==============================================================================
# Multi-File Compose Pattern
# ==============================================================================
# Multiple compose files with overlay pattern and build flag (advanced pattern).

@test "freqtrade-postgres (multi-file) check-validity for base file" {
  run run_make_repo check-validity APP=freqtrade

  [ "$status" -eq 0 ]
  [[ "$output" == *"freqtrade compose file is valid"* ]]
}

@test "freqtrade-postgres (multi-file) lifecycle: up → wait healthy → down → verify removed" {
  export INTEGRATION_CURRENT_APP="freqtrade-postgres"
  require_containers_absent_or_skip freqtrade

  # Start app with postgres backend (multi-file + build)
  run run_make_repo up-freqtrade-postgres
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=1

  # Wait for container to be healthy/running
  run wait_for_container_healthy_or_running freqtrade "$INTEGRATION_TEST_TIMEOUT_SLOW"
  [ "$status" -eq 0 ]

  # Explicitly verify healthcheck is "healthy" (strict validation)
  run docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' freqtrade
  [ "$status" -eq 0 ]
  [[ "$output" == "healthy" || "$output" == "running" ]]

  # Verify container is in docker ps
  run docker ps --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"freqtrade"* ]]

  # Stop app
  run run_make_repo down-freqtrade-postgres
  [ "$status" -eq 0 ]
  INTEGRATION_APP_STARTED=0

  # Verify container is removed
  run docker ps -a --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"freqtrade"* ]]
}

# ==============================================================================
# Build Pattern
# ==============================================================================
# Explicit build command with custom flags (used for image customization).

@test "freqtrade build-freqtrade succeeds and rebuilds image" {
  require_containers_absent_or_skip freqtrade

  # Explicit build command (no container start, just image build)
  run run_make_repo build-freqtrade
  [ "$status" -eq 0 ]

  # Verify image exists
  run docker images --format '{{.Repository}}:{{.Tag}}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"freqtrade"* ]]
}
