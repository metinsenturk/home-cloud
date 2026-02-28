---
name: add-app-test
description: Add or update Makefile tests for a specific app target using table-driven Bats patterns
---

> **Prompt Notes**
> - Purpose: Add/update app-target Makefile tests with consistent table-driven coverage.
> - Default suite: `tests/makefile_app_commands.bats` unless scope requires another suite.
> - Completion rule: Update inline section comments/examples to match final test rows.

You are an expert DevOps test engineer. Your task is to add or update tests for an app target in the root `Makefile`.

# Goal
Ensure app-related Makefile targets are covered by unit-like Bats tests using existing mock infrastructure.

# Inputs (Required)
- `app_name` (example: `blinko`)
- `targets` (one or more, example: `up-blinko`, `down-blinko`, `build-freqtrade`)

# Step 1: Discover command shape from Makefile
Before editing tests, inspect the root `Makefile` and identify for each target:
1. Which compose files are used (`-f` flags)
2. Which env files are used (`--env-file` order)
3. Which compose verb/flags are used (`up -d`, `down`, `build --no-cache`, `--build`, etc.)
4. Whether target is simple single-file compose or multi-file compose

# Step 2: Decide test suite location
Use these rules:
- Per-app command wiring → `tests/makefile_app_commands.bats`
- Aggregate orchestration behavior → `tests/makefile_aggregates.bats`
- Core utility validation → `tests/makefile_core.bats`
- Group backend/lifecycle behavior → `tests/makefile_groups.bats`

For app targets, default to `tests/makefile_app_commands.bats`.

# Step 3: Apply table-driven update (preferred)
In `tests/makefile_app_commands.bats`:
1. Keep existing helper function (`run_and_assert_compose_line`) unchanged unless required.
2. Add rows to the correct table:
   - Simple compose table for single compose-file targets
   - Multi-file compose table for overlay/build patterns
3. Row format must be:
   - `target|expected_docker_argv`
4. `expected_docker_argv` must use TAB-separated args to match mock docker log format.
5. Do NOT create one-off duplicated tests when a table row is sufficient.

# Step 4: Update inline examples/comments
Always update section comments when tasks are completed:
- Add/refresh `Examples explained` bullets so readers can quickly understand why each row exists.
- Update section notes if rows were added, removed, regrouped, or reclassified.
- Keep comments concise and focused on patterns and intent.
- Do not finish the task with stale comments that no longer match table contents.
- If creating a **new test file**, add a top-level explanatory comment block at the start of the file.
- If creating or updating an **instruction/prompt file**, include a top-level notes block that explains purpose and completion expectations.

# Step 5: Validate
Run:
- `make test-makefile`

If tests fail:
- Fix only issues related to your target/test changes.
- Do not refactor unrelated suites.

# Step 6: Documentation update
Update `tests/README.md` only when needed:
- If a new suite file is added
- If coverage scope materially changes

No README changes are needed for routine row additions in existing tables.

# Acceptance Criteria
- New/updated app targets are represented in the correct table-driven suite.
- Command assertions exactly match Makefile behavior (env-file order, compose file order, command flags).
- All tests pass via `make test-makefile`.
- Inline comments/examples are updated and aligned with final table contents.
- Any newly created test/instruction file includes top-level explanatory notes/comments.

# Output style for the final report
Provide a concise summary with:
- What targets were added/updated
- Which test file/table was changed
- Validation command and result
- Comment updates performed (what section comments/examples were refreshed)
- Any doc updates performed
