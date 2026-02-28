# Testing Instructions (Makefile + Bats)

> **File Notes**
> - Purpose: Standardize how Makefile tests are added, updated, and validated.
> - Audience: Contributors editing files under `tests/`.
> - Completion rule: Any test change must include matching inline comment updates.

Use this guide when adding or updating tests in this repository.

## Scope

These rules apply to all test files under `tests/` and especially to Makefile-focused tests using `bats`.

## Prompt Shortcut

When you specifically need to add tests for an app target in the `Makefile`, use:

- `.github/prompts/add-app-test.prompt.md`

This prompt standardizes table-driven updates for `tests/makefile_app_commands.bats` and keeps coverage style consistent.

## Core Principles

- Prefer **unit-like tests with mocks** over real Docker execution.
- Test **behavior and command wiring**, not container runtime correctness.
- Add tests for both:
  - happy paths (success)
  - failure paths (clear error handling)
- Keep tests deterministic and fast.

## Required Patterns

### 1) File Placement

- Core utility targets: `tests/makefile_core.bats`
- Group backend/lifecycle targets: `tests/makefile_groups.bats`
- Per-app command wiring: `tests/makefile_app_commands.bats`
- Meta/aggregate targets: `tests/makefile_aggregates.bats`
- Integration targets (real Docker): `tests/integration/*.bats`
- Shared helpers: `tests/test_helper.bash` (unit-like), `tests/integration/test_helper_integration.bash` (integration)

When adding a new category that does not fit existing files, create a new `tests/makefile_<category>.bats`.

### 2) Naming Convention

- Test names must be explicit and outcome-oriented.
- Format: `"<target> <expected behavior>"`
- Examples:
  - `"check-validity fails when APP is missing"`
  - `"up-base launches traefik, dozzle, and wud in sequence"`

### 3) Table-Driven Coverage (Preferred)

For repeated command-shape validation, use a table-driven loop instead of one test per target.

- Keep one row per target.
- Use `target|expected_docker_argv` format.
- Expected args should use **tab-separated tokens** to match mock docker logs.

### 3.1) Comment Maintenance (Required)

When tests are added or changed, update inline comments in the same file before finishing:

- Keep section headers and intent comments accurate.
- Add or refresh `Examples explained` bullets to cover newly added targets/patterns.
- Ensure comments describe *why* rows exist, not just what the command is.

When a **new test file** is created, it must start with a top-level explanatory comment block that states:

- what the file tests,
- what is intentionally out of scope,
- and any key patterns used (for example: table-driven rows, mocks, sequencing checks).

### 4) Mock-First Strategy

- Use mocks from `tests/helpers/mock-bin/`.
- Never call real Docker or yq in unit-like tests.
- Use helper functions from `tests/test_helper.bash` (`make_in_tmp`, `reset_docker_log`, `docker_log_contains`, etc.).

### 5) Environment and Workspace Safety

- Unit-like tests must run in temporary workspace only.
- Integration tests run against real Docker and must be explicit opt-in (`RUN_INTEGRATION=1`).
- Integration tests should skip disruptive actions if target containers already exist.
- Do not mutate repository state directly outside expected lifecycle/cleanup.
- Ensure line ending safety (CRLF issues are handled by test helper).

## What to Test for New Makefile Targets

When adding a new target, include tests for relevant items:

- Correct `docker compose` command construction
- Correct `--env-file` order (root first, app second if applicable)
- Correct compose file(s) and ordering
- Correct command verb (`up`, `down`, `build`, etc.)
- Expected failure behavior and error messages (if target has guard logic)

For aggregate targets (`up-*` orchestration wrappers), verify:

- dependent targets are invoked
- sequence expectations where meaningful
- completion message output

## Documentation Update Rule

When adding or restructuring tests:

1. Update `tests/README.md`:
   - `Test Files` table
   - scope/coverage notes
2. Keep descriptions concise and aligned with actual test intent.
3. Ensure test-file inline comments were updated to reflect the final test rows.

## Validation Checklist

Before finalizing changes:

- Run:
  - `make test-makefile`
- Confirm all tests pass.
- Ensure new tests are in the correct suite file.
- Ensure no duplicate coverage unless intentionally defensive.
- Ensure inline comments/examples were updated in edited test files.
- Ensure newly created test files include a top-level explanatory comment block.

## Anti-Patterns to Avoid

- One-off duplicated tests when table-driven form is possible.
- Assertions that rely on unstable output ordering unless ordering is the behavior under test.
- Broad assertions that do not verify key command arguments.
- Integration-style behavior in unit-like suites.
