---
name: add-makefile-command
description: Standardized workflow for adding a new command to the Mini-Cloud Makefile
---
You are an expert GNU Make and DevOps engineer. Your task is to ensure a new Makefile command is properly implemented, tested, and documented according to strict quality standards.

# Step 1: Research & Planning

Before implementing any command, you MUST understand the following:

1. **Command Purpose:** What is the intended functionality? (e.g., launching an app, validation check, testing, utility function)
2. **Command Type:** Classify the command into one of these categories:
   - **Service Management:** `up-<appname>`, `down-<appname>` (start/stop individual apps)
   - **Aggregation:** `up-all`, `down-all`, `up-base` (launch/stop groups of services)
   - **Validation:** `check-validity`, `check-tools` (validate configuration/environment)
   - **Testing:** `test-makefile`, `test-makefile-integration-*` (run test suites)
   - **Logging:** `logs-<appname>` (view container logs)
   - **Group Management:** `up-group-*`, `down-group-*` (manage custom groups)
   - **Utility:** `init-env`, `create-network`, `ps` (one-off utility functions)
   - **Custom:** Any command specific to infrastructure or special purposes
3. **Naming Convention:** 
   - Service commands: `up-<appname>`, `down-<appname>`
   - Aggregation: `up-all`, `down-all`, `up-base`, `down-base`
   - Utilities: `<verb>-<subject>` (e.g., `init-env`, `check-validity`)
   - Groups: `up-group-<groupname>`, `down-group-<groupname>`
   - Tests: `test-<subject>[-<variant>]` (e.g., `test-makefile`, `test-makefile-integration-quick`)
4. **Phony Declaration:** Ensure the command is declared as `.PHONY: <command>` to prevent conflicts with filenames.
5. **Environment Handling:** 
   - For app-specific commands: Must use the "Double-Env" pattern (load root `.env` then app `.env`)
   - For utility commands: Determine which `.env` files are needed
   - Use `--env-file .env --env-file apps/<appname>/.env` syntax (in that order)
6. **Dependencies:** Identify if the command depends on other commands:
   - Does it require `create-network` to be run first?
   - Does it depend on another app being running?
   - Should it be part of an aggregation target?
7. **Targets:** Determine all related targets:
   - Primary command target
   - Any prerequisite targets (e.g., `create-network`)
8. **Conditionals & Error Handling:** 
   - Should the command check if directories/files exist?
   - Should it validate before executing?
   - What error messages should be displayed?
9. **Test Requirements:**
   - Unit tests (fast, no real containers): Must always be provided
   - Integration tests (real Docker): Optional but recommended for complex commands
   - Where do tests live: `tests/makefile_*.bats` for Makefile tests
10. **Documentation Requirements:**
    - Inline command documentation (comments in Makefile)
    - Section in `MAKEFILE.md` with examples and explanation
    - Updating existing sections if the command fits into a category
    - Any special notes or caveats
11. **Additional Files to Update:**
    - `MAKEFILE.md` (documentation)
    - `tests/makefile_*.bats` (unit tests)
    - `tests/integration/makefile_*.bats` (integration tests, if applicable)
    - `groups.mk.example` (if command is group-related)
    - `groups.yaml.example` (if command is group-related)
    - `.github/prompts/` (if this is now a standard workflow)
    - `README.md` (only if it's a major user-facing command)

---

# Step 2: User Confirmation and Proposal

Present a detailed "Implementation Plan" to the user and WAIT for their approval. Do not implement yet.

Include the following sections:

## Command Overview
- **Name:** <command-name>
- **Type:** <category> (e.g., Service Management, Validation, Utility)
- **Purpose:** Brief description of what the command does
- **Examples:** Show typical usage (e.g., `make up-myapp`, `make check-validity APP=myapp`)

## Implementation Details
- **Phony Declaration:** `.PHONY: <command> [dependencies]`
- **Dependencies:** List any prerequisite commands (e.g., `create-network`)
- **Environment Variables:** 
  - Specify which `.env` file(s) will be loaded
  - For app commands: Root `.env` + `apps/<appname>/.env`
  - For utility commands: Note which variables are needed
- **Docker Compose Usage (if applicable):** 
  - Show the exact docker compose command that will be executed
  - Verify the `--env-file` order is correct (root first, app second)
  - Confirm `--file` argument points to the correct compose file
- **Error Handling Strategy:** 
  - How will the command validate inputs?
  - What error messages will be shown for common failures?
- **Success Criteria:** What indicates the command executed successfully?

## Testing Strategy
- **Unit Tests:**
  - Which test file will contain the tests? (e.g., `tests/makefile_app_commands.bats`)
  - List of test cases (e.g., "Test that command creates network", "Test that command fails if app directory doesn't exist")
  - Testing approach (mocked Docker vs. no Docker for unit tests)
- **Integration Tests (if applicable):**
  - Which test file? (e.g., `tests/integration/makefile_app_commands.bats`)
  - List of test scenarios using real Docker
  - Time estimate

## Documentation Plan
- **Inline Comments:**
  - Where will comments be added in the Makefile?
  - What will they explain?
- **MAKEFILE.md Updates:**
  - Which section will this command be documented under? (e.g., "🚀 Launching Services", "🧪 Testing")
  - Will it require a new section or fit into an existing one?
  - Examples and explanations to be added
- **Other Files:**
  - Any other files that need updates? (e.g., `groups.mk.example`, `README.md`)

## Files to Create/Modify
List all files that will be created or modified:
- `Makefile` (new command, may update aggregates)
- `MAKEFILE.md` (documentation)
- `tests/makefile_*.bats` (unit tests)
- `tests/integration/makefile_*.bats` (integration tests, if applicable)
- Other files as needed

---

# Step 3: Implementation (After Approval)

Once the user approves the plan, follow these steps:

### 1. Update the Makefile
- Add `.PHONY: <command>` declaration(s) with all dependencies listed
- Implement the command target with clear, documented logic
- Add inline comments explaining non-obvious behavior
- Follow the existing code style and conventions
- If the command is part of an aggregation (like `up-all`), update those targets as well

### 2. Add Unit Tests
- Create or update `tests/makefile_<category>.bats` with test cases
- Each test should:
  - Have a clear, descriptive name
  - Test one specific aspect of the command
  - Use mocked Docker (no real containers) for speed
  - Verify both success and failure scenarios
- Use `bats` assertions (e.g., `assert_success`, `assert_failure`, `assert_output`)
- Follow existing test patterns in the test files

### 3. Add Integration Tests (if applicable)
- Create or update `tests/integration/makefile_<category>.bats`
- Tests should:
  - Use real Docker to verify end-to-end behavior
  - Be marked with `@test "..." {` 
  - Verify actual Docker Compose execution, not just mocking
- Integration tests are slower but provide stronger guarantees

### 4. Update MAKEFILE.md
- Find the appropriate section (or create a new one if needed)
- Add subsection with:
  - **Command syntax:** `make <command> [ARGS]`
  - **Description:** What it does
  - **Examples:** 2-3 realistic usage examples
  - **Output:** What successful output looks like
  - **Environment Variables:** Which `.env` variables are used (if non-obvious)
- Maintain the existing structure and tone

### 5. Update Other Files
- Update `groups.mk.example` if the command is group-related
- Update `groups.yaml.example` if the command is group-related
- Update `README.md` only if this is a major user-facing command

### 6. Validation
- Run the unit tests to verify they pass
- Run integration tests if applicable
- Manually test the command if possible
- Verify all documentation is complete and accurate

---

## Template for Implementation Plan Response

When presenting the Implementation Plan to the user, use this structure:

```markdown
## Command Implementation Plan

### ✅ Command Overview
- **Name:** `make <command>`
- **Type:** <category>
- **Purpose:** <one-line description>
- **Example Usage:** `make <command> [ARGS]`

### 📋 Implementation Details
- **Phony Declaration:** `.PHONY: <command> [dep1 dep2]`
- **Dependencies:** Requires `<command1>`, `<command2>`
- **Environment:** Loads root `.env` + app `.env`
- **Error Handling:** Validates [X], fails if [Y]

### 🧪 Testing
- **Unit Tests:** `tests/makefile_<category>.bats` (N test cases)
- **Integration Tests:** `tests/integration/makefile_<category>.bats` (optional, N scenarios)

### 📖 Documentation
- **MAKEFILE.md:** Add to section "X. Y. Z"
- **Inline Comments:** [Brief explanation of where]
- **Other Files:** [Any updates needed]

### 📝 Files to Modify
- [ ] Makefile
- [ ] MAKEFILE.md
- [ ] tests/makefile_<category>.bats
- [ ] tests/integration/makefile_<category>.bats (optional)
- [ ] [Other files if needed]

**Total Changes:** X files modified, Y tests added, Z documentation sections updated

**Estimated Time:** [X minutes implementation + Y minutes testing]

---

### Do you approve this plan? (yes/no)
```

---

## Additional Guidance

### Makefile Best Practices
1. **Comments:** Use `# ` for inline comments explaining non-obvious behavior
2. **Variables:** Prefer explicit paths over variables when clarity improves
3. **Dependencies:** Always use `.PHONY:` for targets that don't create files
4. **Error Handling:** Use `$(error ...)` for critical failures, echo warnings for minor issues
5. **Consistency:** Follow the style of existing commands

### Test Writing Best Practices
1. **Clarity:** Test names should describe exactly what is being tested
2. **Isolation:** Each test should be independent and not rely on others
3. **Assertions:** Use specific assertions, not generic `[ $? -eq 0 ]`
4. **Mocking:** Unit tests should mock Docker to run fast
5. **Integration:** Only use real Docker in integration tests

### Documentation Best Practices
1. **Examples:** Always include 2-3 realistic examples
2. **Clarity:** Explain WHY something works, not just HOW
3. **Completeness:** Document all command arguments and options
4. **Consistency:** Match the tone and structure of existing documentation
5. **Updates:** Keep documentation in sync with code changes

---

## Common Pitfalls to Avoid

1. ❌ **Missing `.PHONY` declaration** → Command fails if file with same name exists
2. ❌ **Wrong `.env` file order** → App-specific variables don't override globals
3. ❌ **No error handling** → Command silently fails or produces cryptic errors
4. ❌ **Tests without documentation** → Users don't know the command exists or how to use it
5. ❌ **Forgetting aggregation targets** → Command exists but doesn't work in `make up-all`
6. ❌ **Hardcoded paths** → Command fails on different systems or directory structures
7. ❌ **Missing integration tests** → Complex commands break when Docker behavior changes
