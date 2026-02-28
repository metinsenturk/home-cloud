#!/usr/bin/env bash

# Integration test helper utilities for Makefile end-to-end tests.
#
# This helper runs against the real Docker daemon and repository files.
# It provides strict safety gates so integration tests are opt-in and
# avoid disrupting already-running local stacks.

integration_setup_common() {
  export INTEGRATION_REPO_ROOT
  INTEGRATION_REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

  export INTEGRATION_MAKE_BIN
  INTEGRATION_MAKE_BIN="$(command -v make)"

  # Configurable timeout for container health checks (in seconds).
  # Default: 180s for normal apps, 300s for slow builds (freqtrade, etc.)
  # Override: INTEGRATION_TEST_TIMEOUT=300 make test-makefile-integration
  export INTEGRATION_TEST_TIMEOUT=${INTEGRATION_TEST_TIMEOUT:-180}
  export INTEGRATION_TEST_TIMEOUT_SLOW=${INTEGRATION_TEST_TIMEOUT_SLOW:-300}

  # Test tier stratification for performance tuning.
  # quick: Sanity checks only (check-validity, network) - ~30-60s total
  # full:  Deep lifecycle testing (startup, healthcheck, teardown) - 3-5 minutes
  # Default: quick (recommend full in CI)
  export RUN_INTEGRATION_TIER=${RUN_INTEGRATION_TIER:-quick}

  if [[ "${RUN_INTEGRATION:-0}" != "1" ]]; then
    skip "Integration tests are disabled. Run with RUN_INTEGRATION=1."
  fi

  if ! command -v docker > /dev/null 2>&1; then
    skip "docker is required for integration tests"
  fi

  if ! command -v "$INTEGRATION_MAKE_BIN" > /dev/null 2>&1; then
    skip "make is required for integration tests"
  fi

  if ! docker info > /dev/null 2>&1; then
    skip "Docker daemon is not reachable"
  fi

  if [ ! -f "$INTEGRATION_REPO_ROOT/.env" ]; then
    skip "Root .env file is required for integration tests"
  fi
}

run_make_repo() {
  (
    cd "$INTEGRATION_REPO_ROOT" || exit 1
    "$INTEGRATION_MAKE_BIN" "$@"
  )
}

any_container_exists() {
  local name
  for name in "$@"; do
    if docker ps -a --format '{{.Names}}' | grep -Fx "$name" > /dev/null; then
      return 0
    fi
  done
  return 1
}

require_containers_absent_or_skip() {
  if any_container_exists "$@"; then
    skip "One or more target containers already exist; skipping disruptive integration test"
  fi
}

wait_for_container_healthy_or_running() {
  local container_name="$1"
  local timeout_seconds="${2:-120}"
  local start_epoch current_epoch state

  start_epoch="$(date +%s)"
  while true; do
    if ! docker inspect "$container_name" > /dev/null 2>&1; then
      sleep 2
    else
      state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_name" 2>/dev/null || true)"
      if [ "$state" = "healthy" ] || [ "$state" = "running" ]; then
        return 0
      fi
      if [ "$state" = "unhealthy" ] || [ "$state" = "exited" ] || [ "$state" = "dead" ]; then
        return 1
      fi
      sleep 2
    fi

    current_epoch="$(date +%s)"
    if [ $((current_epoch - start_epoch)) -ge "$timeout_seconds" ]; then
      return 1
    fi
  done
}
