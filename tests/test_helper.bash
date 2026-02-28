#!/usr/bin/env bash

setup() {
  export MAKEFILE_TEST_ROOT
  MAKEFILE_TEST_ROOT="$(mktemp -d)"

  cp "$BATS_TEST_DIRNAME/../Makefile" "$MAKEFILE_TEST_ROOT/Makefile"
  cp "$BATS_TEST_DIRNAME/../groups.mk.example" "$MAKEFILE_TEST_ROOT/groups.mk.example"
  cp "$BATS_TEST_DIRNAME/../groups.yaml.example" "$MAKEFILE_TEST_ROOT/groups.yaml.example"

  export MAKE_BIN
  MAKE_BIN="$(command -v make)"

  export ORIGINAL_PATH="$PATH"
  export PATH="$BATS_TEST_DIRNAME/helpers/mock-bin:$ORIGINAL_PATH"
}

teardown() {
  rm -rf "$MAKEFILE_TEST_ROOT"
}

make_in_tmp() {
  (
    cd "$MAKEFILE_TEST_ROOT" || exit 1
    "$MAKE_BIN" "$@"
  )
}
