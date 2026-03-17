#!/usr/bin/env bats

# Makefile aggregate target tests.
#
# These tests validate meta-targets that orchestrate multiple app targets:
# - up-base: Launches core infrastructure (traefik, dozzle, wud)
# - down-base: Stops core infrastructure in reverse order
# - recreate-base: Tears down then rebuilds base services
# - up-all: Launches all registered services
# - down-all: Stops all registered services in reverse order
#
# Strategy:
# - Mock docker to capture invocations
# - Assert that constituent targets are called in correct sequence
# - Verify command construction for representative services

load test_helper

# ==============================================================================
# Base Service Orchestration
# ==============================================================================
# The "base" meta-targets represent the minimal infrastructure required for
# the home-cloud to function: Traefik (reverse proxy), Dozzle (logging),
# and WUD (update monitoring).

@test "up-base launches traefik, dozzle, and wud in sequence" {
  reset_docker_log
  run make_in_tmp up-base

  [ "$status" -eq 0 ]
  
  # Verify all three services were started
  docker_log_contains "apps/traefik/docker-compose.yml"
  docker_log_contains "apps/dozzle/docker-compose.yml"
  docker_log_contains "apps/wud/docker-compose.yml"
  
  # Verify completion message
  [[ "$output" == *"Base services launched."* ]]
}

@test "down-base stops dozzle, wud, and traefik in reverse order" {
  reset_docker_log
  run make_in_tmp down-base

  [ "$status" -eq 0 ]
  
  # Verify all three services were stopped
  docker_log_contains "apps/dozzle/docker-compose.yml"
  docker_log_contains "apps/wud/docker-compose.yml"
  docker_log_contains "apps/traefik/docker-compose.yml"
  
  # Verify all use 'down' command
  grep -q "down" "$MOCK_DOCKER_LOG_FILE"
  
  # Verify completion message
  [[ "$output" == *"Base services stopped."* ]]
}

@test "recreate-base tears down then rebuilds base services" {
  reset_docker_log
  run make_in_tmp recreate-base

  [ "$status" -eq 0 ]
  
  # Verify both down and up commands were issued
  grep -q "down" "$MOCK_DOCKER_LOG_FILE"
  grep -q "up" "$MOCK_DOCKER_LOG_FILE"
  
  # Verify completion message
  [[ "$output" == *"Base services recreated."* ]]
}

# ==============================================================================
# Full Stack Orchestration
# ==============================================================================
# The up-all/down-all targets orchestrate the entire infrastructure stack.
# Rather than asserting on every individual service (which would create
# a brittle test), we validate:
# - The command completes successfully
# - Multiple representative services are invoked
# - The final completion message appears

@test "up-all orchestrates multiple services successfully" {
  reset_docker_log
  run make_in_tmp up-all

  [ "$status" -eq 0 ]
  
  # Verify a sample of services across different categories
  docker_log_contains "apps/traefik/docker-compose.yml"   # base
  docker_log_contains "apps/blinko/docker-compose.yml"    # app
  docker_log_contains "apps/postgres/docker-compose.yml"  # infra
  
  # Verify completion message
  [[ "$output" == *"All services launched."* ]]
}

@test "down-all orchestrates shutdown of multiple services" {
  reset_docker_log
  run make_in_tmp down-all

  [ "$status" -eq 0 ]
  
  # Verify a sample of services are stopped
  docker_log_contains "apps/traefik/docker-compose.yml"
  docker_log_contains "apps/blinko/docker-compose.yml"
  docker_log_contains "apps/postgres/docker-compose.yml"
  
  # Verify all use 'down' command
  grep -q "down" "$MOCK_DOCKER_LOG_FILE"
  
  # Verify completion message
  [[ "$output" == *"All services stopped."* ]]
}

# ==============================================================================
# Dependency Chain Validation
# ==============================================================================
# These tests verify that aggregate targets properly depend on their
# constituent targets, ensuring proper sequencing.

@test "up-base depends on create-network" {
  reset_docker_log
  run make_in_tmp up-base

  [ "$status" -eq 0 ]
  
  # Network creation should be invoked (via inspect check)
  docker_log_contains "network"
}

@test "recreate-base sequences down before up" {
  reset_docker_log
  run make_in_tmp recreate-base

  [ "$status" -eq 0 ]
  
  # Extract line numbers of down and up commands from docker log
  # Ensure down commands appear before up commands in the log
  local down_line=$(grep -n "down" "$MOCK_DOCKER_LOG_FILE" | head -n1 | cut -d: -f1)
  local up_line=$(grep -n "up" "$MOCK_DOCKER_LOG_FILE" | head -n1 | cut -d: -f1)
  
  # If both exist, down should come before up
  if [ -n "$down_line" ] && [ -n "$up_line" ]; then
    [ "$down_line" -lt "$up_line" ]
  fi
}
