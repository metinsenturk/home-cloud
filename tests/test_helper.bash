#!/usr/bin/env bash

# Test helper utilities for Makefile unit-like tests.
#
# This file provides a clean temporary workspace for each test, injects
# mocked binaries (docker/yq), and exposes a helper to run make commands
# against the copied fixtures instead of the real repository files.

setup() {
  # Create an isolated temp directory for each test run.
  export MAKEFILE_TEST_ROOT
  MAKEFILE_TEST_ROOT="$(mktemp -d)"

  # Copy only the files required by the Makefile group-command tests.
  cp "$BATS_TEST_DIRNAME/../Makefile" "$MAKEFILE_TEST_ROOT/Makefile"
  cp "$BATS_TEST_DIRNAME/../groups.mk.example" "$MAKEFILE_TEST_ROOT/groups.mk.example"
  cp "$BATS_TEST_DIRNAME/../groups.yaml.example" "$MAKEFILE_TEST_ROOT/groups.yaml.example"

  # Normalize line endings for copied fixtures to avoid shell issues on WSL.
  sed -i 's/\r$//' "$MAKEFILE_TEST_ROOT/Makefile"
  sed -i 's/\r$//' "$MAKEFILE_TEST_ROOT/groups.mk.example"
  sed -i 's/\r$//' "$MAKEFILE_TEST_ROOT/groups.yaml.example"

  # Normalize and chmod mock binaries so they are executable on Linux/WSL.
  sed -i 's/\r$//' "$BATS_TEST_DIRNAME/helpers/mock-bin/docker"
  sed -i 's/\r$//' "$BATS_TEST_DIRNAME/helpers/mock-bin/yq"
  chmod +x "$BATS_TEST_DIRNAME/helpers/mock-bin/docker"
  chmod +x "$BATS_TEST_DIRNAME/helpers/mock-bin/yq"

  # Save make path once; tests call it through make_in_tmp.
  export MAKE_BIN
  MAKE_BIN="$(command -v make)"

  # Prepend mocks to PATH while preserving original PATH for specific tests.
  export ORIGINAL_PATH="$PATH"
  export PATH="$BATS_TEST_DIRNAME/helpers/mock-bin:$ORIGINAL_PATH"
}

teardown() {
  # Remove per-test temp directory to keep tests isolated and repeatable.
  rm -rf "$MAKEFILE_TEST_ROOT"
}

make_in_tmp() {
  # Run make from the temporary workspace so tests never modify repo files.
  (
    cd "$MAKEFILE_TEST_ROOT" || exit 1
    "$MAKE_BIN" "$@"
  )
}
