#!/usr/bin/env bats

# Makefile group-command unit-like tests.
#
# These tests validate command behavior (exit codes and output) for:
# - make/yaml group backends
# - init/clean/list group lifecycle commands
# - generic group execution and shortcut aliases
# - expected error paths (invalid backend, missing yq)
#
# External dependencies are mocked via tests/helpers/mock-bin.

load test_helper

# Verifies that make-backend initialization creates groups.mk from template.
@test "init-groups creates groups.mk in make backend" {
  run make_in_tmp init-groups

  [ "$status" -eq 0 ]
  [[ "$output" == *"Created groups.mk from example"* ]]
  [ -f "$MAKEFILE_TEST_ROOT/groups.mk" ]
}

# Verifies overwrite protection when groups.mk already exists.
@test "init-groups fails when groups.mk already exists" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp init-groups
  [ "$status" -ne 0 ]
  [[ "$output" == *"groups.mk already exists"* ]]
}

# Verifies cleanup command removes generated groups.mk.
@test "clean-groups removes groups.mk" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp clean-groups
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed groups.mk"* ]]
  [ ! -f "$MAKEFILE_TEST_ROOT/groups.mk" ]
}

# Verifies list command reports a clear error when make groups are undefined.
@test "list-groups in make backend fails without groups file" {
  run make_in_tmp list-groups

  [ "$status" -ne 0 ]
  [[ "$output" == *"no groups defined in groups.mk"* ]]
}

# Verifies list command returns configured group names in make backend.
@test "list-groups in make backend lists groups after init" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp list-groups
  [ "$status" -eq 0 ]
  [[ "$output" == *"favorites finance school"* ]]
}

# Verifies up-group target iterates all apps in declared order for make backend.
@test "up-group-favorites in make backend iterates apps" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp up-group-favorites
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
  [[ "$output" == *"→ Starting glance"* ]]
  [[ "$output" == *"→ Starting jupyter"* ]]
}

# Verifies shortcut alias forwards to its generic group target.
@test "up-favorites alias forwards to up-group-favorites" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp up-favorites
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
}

# Verifies down alias forwards to the generic down-group target.
@test "down-favorites alias forwards to down-group-favorites" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp down-favorites
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Stopping blinko"* ]]
}

# Verifies unknown group fails with a clear error in make backend.
@test "up-group fails when group does not exist" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp up-group-does-not-exist
  [ "$status" -ne 0 ]
  [[ "$output" == *"group 'does-not-exist' not found or empty"* ]]
}

# Verifies empty group definitions are rejected.
@test "up-group fails when group is empty" {
  cat > "$MAKEFILE_TEST_ROOT/groups.mk" <<'EOF'
GROUPS := empty
GROUP_empty :=
EOF

  run make_in_tmp up-group-empty
  [ "$status" -ne 0 ]
  [[ "$output" == *"group 'empty' not found or empty"* ]]
}

# Verifies failure from an unknown app target propagates out of group execution.
@test "up-group fails when group contains unknown app target" {
  cat > "$MAKEFILE_TEST_ROOT/groups.mk" <<'EOF'
GROUPS := broken
GROUP_broken := app-does-not-exist
EOF

  run make_in_tmp up-group-broken
  [ "$status" -ne 0 ]
  [[ "$output" == *"No rule to make target 'up-app-does-not-exist'"* ]]
}

# Verifies unknown backend values fail with an explicit error message.
@test "invalid GROUPS_BACKEND returns error" {
  run make_in_tmp list-groups GROUPS_BACKEND=invalid

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid GROUPS_BACKEND='invalid'"* ]]
}

# Verifies yaml-backend initialization creates groups.yaml from template.
@test "init-groups creates groups.yaml in yaml backend" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml

  [ "$status" -eq 0 ]
  [[ "$output" == *"Created groups.yaml from example"* ]]
  [ -f "$MAKEFILE_TEST_ROOT/groups.yaml" ]
}

# Verifies yaml backend can list groups via mocked yq parser.
@test "list-groups in yaml backend lists groups" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  run make_in_tmp list-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"favorites"* ]]
  [[ "$output" == *"finance"* ]]
  [[ "$output" == *"school"* ]]
}

# Verifies yaml backend executes apps from a named group.
@test "up-group-favorites in yaml backend iterates apps" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  run make_in_tmp up-group-favorites GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
  [[ "$output" == *"→ Starting glance"* ]]
  [[ "$output" == *"→ Starting jupyter"* ]]
}

# Verifies yaml backend reports missing dependency when yq is unavailable.
@test "list-groups in yaml backend fails when yq is missing" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  PATH="$ORIGINAL_PATH"
  run make_in_tmp list-groups GROUPS_BACKEND=yaml

  [ "$status" -ne 0 ]
  [[ "$output" == *"yq is required for GROUPS_BACKEND=yaml"* ]]
}
