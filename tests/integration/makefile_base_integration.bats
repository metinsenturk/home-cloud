#!/usr/bin/env bats

# Makefile base integration tests (real Docker).
#
# Scope:
# - Validates end-to-end behavior for phase 1-3 integration coverage.
# - Uses real Makefile targets and real Docker daemon.
#
# Out of scope:
# - Full app matrix lifecycle testing (phase 4).
# - External HTTP checks through Traefik routing.
#
# Safety model:
# - Tests are opt-in via RUN_INTEGRATION=1.
# - Disruptive tests are skipped if target containers already exist.
# - Base stack is cleaned up after each test when created by the test.

load test_helper_integration

setup() {
  integration_setup_common
  export INTEGRATION_BASE_STACK_STARTED=0
}

teardown() {
  if [ "${INTEGRATION_BASE_STACK_STARTED:-0}" -eq 1 ]; then
    run_make_repo down-base > /dev/null 2>&1 || true
  fi
}

@test "create-network is idempotent with real docker" {
  run run_make_repo create-network
  [ "$status" -eq 0 ]

  run run_make_repo create-network
  [ "$status" -eq 0 ]

  run docker network inspect home_network
  [ "$status" -eq 0 ]
}

@test "check-validity APP=traefik succeeds with real compose config" {
  run run_make_repo check-validity APP=traefik

  [ "$status" -eq 0 ]
  [[ "$output" == *"traefik compose file is valid"* ]]
}

@test "up-base starts base containers and down-base removes them" {
  require_containers_absent_or_skip traefik dozzle wud

  run run_make_repo up-base
  [ "$status" -eq 0 ]
  [[ "$output" == *"Base services launched."* ]]
  INTEGRATION_BASE_STACK_STARTED=1

  run wait_for_container_healthy_or_running traefik 180
  [ "$status" -eq 0 ]
  run wait_for_container_healthy_or_running dozzle 180
  [ "$status" -eq 0 ]
  run wait_for_container_healthy_or_running wud 180
  [ "$status" -eq 0 ]

  run run_make_repo down-base
  [ "$status" -eq 0 ]
  [[ "$output" == *"Base services stopped."* ]]
  INTEGRATION_BASE_STACK_STARTED=0

  run docker ps -a --format '{{.Names}}'
  [ "$status" -eq 0 ]
  [[ "$output" != *"traefik"* ]]
  [[ "$output" != *"dozzle"* ]]
  [[ "$output" != *"wud"* ]]
}

@test "recreate-base recovers base stack and reports completion" {
  require_containers_absent_or_skip traefik dozzle wud

  run run_make_repo recreate-base
  [ "$status" -eq 0 ]
  [[ "$output" == *"Base services recreated."* ]]
  INTEGRATION_BASE_STACK_STARTED=1

  run wait_for_container_healthy_or_running traefik 180
  [ "$status" -eq 0 ]
  run wait_for_container_healthy_or_running dozzle 180
  [ "$status" -eq 0 ]
  run wait_for_container_healthy_or_running wud 180
  [ "$status" -eq 0 ]
}
