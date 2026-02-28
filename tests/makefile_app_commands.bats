#!/usr/bin/env bats

# Makefile per-app command construction tests.
#
# These tests assert docker compose argument wiring for representative targets.
# They do not start real containers; assertions read the mocked docker log.

load test_helper

# Verifies base service command uses root env file and traefik compose path.
@test "up-traefik composes with root env and traefik file" {
  reset_docker_log

  run make_in_tmp up-traefik

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t-f\tapps/traefik/docker-compose.yml\tup\t-d'
}

# Verifies standard app command uses root + app env files and correct compose file.
@test "up-blinko composes with root and app env files" {
  reset_docker_log

  run make_in_tmp up-blinko

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/blinko/.env\t-f\tapps/blinko/docker-compose.yml\tup\t-d'
}

# Verifies standard down command keeps the same env/compose wiring.
@test "down-blinko composes with down action" {
  reset_docker_log

  run make_in_tmp down-blinko

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/blinko/.env\t-f\tapps/blinko/docker-compose.yml\tdown'
}

# Verifies infra app wiring uses underscore path and expected env file.
@test "up-infra-postgres uses infra path and env file" {
  reset_docker_log

  run make_in_tmp up-infra-postgres

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/infra_postgres/.env\t-f\tapps/infra_postgres/docker-compose.yml\tup\t-d'
}

# Verifies multi-file compose command for freqtrade postgres up target.
@test "up-freqtrade-postgres uses both compose files and build" {
  reset_docker_log

  run make_in_tmp up-freqtrade-postgres

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/freqtrade/.env\t-f\tapps/freqtrade/docker-compose.yml\t-f\tapps/freqtrade/docker-compose.postgres.yml\tup\t-d\t--build'
}

# Verifies multi-file compose command for freqtrade postgres down target.
@test "down-freqtrade-postgres uses both compose files and down" {
  reset_docker_log

  run make_in_tmp down-freqtrade-postgres

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/freqtrade/.env\t-f\tapps/freqtrade/docker-compose.yml\t-f\tapps/freqtrade/docker-compose.postgres.yml\tdown'
}

# Verifies build target uses both files and no-cache option.
@test "build-freqtrade uses both compose files and no-cache" {
  reset_docker_log

  run make_in_tmp build-freqtrade

  [ "$status" -eq 0 ]
  docker_log_contains $'docker\tcompose\t--env-file\t.env\t--env-file\tapps/freqtrade/.env\t-f\tapps/freqtrade/docker-compose.yml\t-f\tapps/freqtrade/docker-compose.postgres.yml\tbuild\t--no-cache'
}
