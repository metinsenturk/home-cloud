#!/usr/bin/env bats

# Makefile core unit-like tests.
#
# These tests validate non-group utility command behavior, including:
# - create-network branching logic
# - check-validity argument and compose validation paths
#
# External commands are mocked through tests/helpers/mock-bin.

load test_helper

# Verifies create-network reports existing network when inspect succeeds.
@test "create-network reports already exists when inspect succeeds" {
  run make_in_tmp create-network

  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
}

# Verifies create-network attempts creation when inspect fails.
@test "create-network creates network when inspect fails" {
  export MOCK_DOCKER_NETWORK_INSPECT_FAIL=1
  run make_in_tmp create-network
  unset MOCK_DOCKER_NETWORK_INSPECT_FAIL

  [ "$status" -eq 0 ]
  [[ "$output" == *"created"* ]]
}

# Verifies check-validity requires APP to be set.
@test "check-validity fails when APP is missing" {
  run make_in_tmp check-validity

  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage: make check-validity APP=app_name"* ]]
}

# Verifies check-validity fails when compose file for APP does not exist.
@test "check-validity fails when app compose file is missing" {
  run make_in_tmp check-validity APP=notreal

  [ "$status" -ne 0 ]
  [[ "$output" == *"apps/notreal/docker-compose.yml not found"* ]]
}

# Verifies check-validity success path with mocked docker compose config.
@test "check-validity succeeds when compose config is valid" {
  mkdir -p "$MAKEFILE_TEST_ROOT/apps/demo"
  printf 'services:\n  demo:\n    image: demo:latest\n' > "$MAKEFILE_TEST_ROOT/apps/demo/docker-compose.yml"

  run make_in_tmp check-validity APP=demo

  [ "$status" -eq 0 ]
  [[ "$output" == *"demo compose file is valid"* ]]
}

# Verifies check-validity failure path when docker compose config fails.
@test "check-validity fails when compose config is invalid" {
  mkdir -p "$MAKEFILE_TEST_ROOT/apps/demo"
  printf 'services:\n  demo:\n    image: demo:latest\n' > "$MAKEFILE_TEST_ROOT/apps/demo/docker-compose.yml"

  export MOCK_DOCKER_COMPOSE_CONFIG_FAIL=1
  run make_in_tmp check-validity APP=demo
  unset MOCK_DOCKER_COMPOSE_CONFIG_FAIL

  [ "$status" -ne 0 ]
  [[ "$output" == *"demo compose file is invalid"* ]]
}
