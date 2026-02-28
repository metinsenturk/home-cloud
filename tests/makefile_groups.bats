#!/usr/bin/env bats

load test_helper

@test "init-groups creates groups.mk in make backend" {
  run make_in_tmp init-groups

  [ "$status" -eq 0 ]
  [[ "$output" == *"Created groups.mk from example"* ]]
  [ -f "$MAKEFILE_TEST_ROOT/groups.mk" ]
}

@test "init-groups fails when groups.mk already exists" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp init-groups
  [ "$status" -ne 0 ]
  [[ "$output" == *"groups.mk already exists"* ]]
}

@test "clean-groups removes groups.mk" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp clean-groups
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed groups.mk"* ]]
  [ ! -f "$MAKEFILE_TEST_ROOT/groups.mk" ]
}

@test "list-groups in make backend fails without groups file" {
  run make_in_tmp list-groups

  [ "$status" -ne 0 ]
  [[ "$output" == *"no groups defined in groups.mk"* ]]
}

@test "list-groups in make backend lists groups after init" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp list-groups
  [ "$status" -eq 0 ]
  [[ "$output" == *"favorites finance school"* ]]
}

@test "up-group-favorites in make backend iterates apps" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp up-group-favorites
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
  [[ "$output" == *"→ Starting glance"* ]]
  [[ "$output" == *"→ Starting jupyter"* ]]
}

@test "up-favorites alias forwards to up-group-favorites" {
  run make_in_tmp init-groups
  [ "$status" -eq 0 ]

  run make_in_tmp up-favorites
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
}

@test "invalid GROUPS_BACKEND returns error" {
  run make_in_tmp list-groups GROUPS_BACKEND=invalid

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid GROUPS_BACKEND='invalid'"* ]]
}

@test "init-groups creates groups.yaml in yaml backend" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml

  [ "$status" -eq 0 ]
  [[ "$output" == *"Created groups.yaml from example"* ]]
  [ -f "$MAKEFILE_TEST_ROOT/groups.yaml" ]
}

@test "list-groups in yaml backend lists groups" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  run make_in_tmp list-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"favorites"* ]]
  [[ "$output" == *"finance"* ]]
  [[ "$output" == *"school"* ]]
}

@test "up-group-favorites in yaml backend iterates apps" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  run make_in_tmp up-group-favorites GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"→ Starting blinko"* ]]
  [[ "$output" == *"→ Starting glance"* ]]
  [[ "$output" == *"→ Starting jupyter"* ]]
}

@test "list-groups in yaml backend fails when yq is missing" {
  run make_in_tmp init-groups GROUPS_BACKEND=yaml
  [ "$status" -eq 0 ]

  PATH="$ORIGINAL_PATH"
  run make_in_tmp list-groups GROUPS_BACKEND=yaml

  [ "$status" -ne 0 ]
  [[ "$output" == *"yq is required for GROUPS_BACKEND=yaml"* ]]
}
