# Makefile Tests (Unit-like + Integration)

This directory contains both:
- Unit-like tests (mocked Docker/yq, fast and safe by default)
- Integration tests (real Docker daemon, opt-in)

## Requirements

- `bash`
- `make`
- `bats` (bats-core)

## Install bats (bats-core)

### Ubuntu / WSL

```bash
sudo apt-get update
sudo apt-get install -y bats
```

### macOS (Homebrew)

```bash
brew install bats-core
```

### Node/NPM (alternative)

```bash
npm install -g bats
```

### Verify install

```bash
bats --version
```

## Run tests

### Unit-like tests (default)

```bash
bats tests/*.bats
```

or

```bash
make test-makefile
```

### Integration tests (real Docker, opt-in)

**Quick tier (default):** Fast sanity checks - network creation, compose validation (~30-60s)

```bash
RUN_INTEGRATION=1 make test-makefile-integration
```

or equivalently:

```bash
RUN_INTEGRATION=1 make test-makefile-integration-quick
```

**Full tier:** Complete app lifecycle tests - startup, healthcheck validation, teardown (3-5 minutes)

```bash
RUN_INTEGRATION=1 make test-makefile-integration-full
```

Direct bats invocation with tier control:

```bash
# Quick tier only
RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=quick bats tests/integration/*.bats

# Full tier (app lifecycle tests)
RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=full bats tests/integration/*.bats
```

### Configuring Integration Test Timeouts

Container startup and healthcheck waits vary by system performance. Override timeouts with environment variables:

```bash
# Standard timeout (default 180s) - use for slow systems or internet
INTEGRATION_TEST_TIMEOUT=300 RUN_INTEGRATION=1 make test-makefile-integration

# Separate timeout for slow builds like freqtrade-postgres (default 300s)
INTEGRATION_TEST_TIMEOUT_SLOW=600 RUN_INTEGRATION=1 make test-makefile-integration

# Override both at once
INTEGRATION_TEST_TIMEOUT=300 INTEGRATION_TEST_TIMEOUT_SLOW=600 \
  RUN_INTEGRATION=1 make test-makefile-integration
```

### All tests

Run unit tests only (default, fast):

```bash
make test-makefile-all
```

Run unit tests + integration quick tier (recommended for local development):

```bash
RUN_INTEGRATION=1 make test-makefile-all
```

Run everything including full integration tier (recommended for CI):

```bash
RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=full make test-makefile-all
```

**Tier selection guide:**
- **Quick** (default): Fast feedback loop, safe to run locally anytime
- **Full** (opt-in): Complete validation, run before merging or in CI pipelines

## Test Files

| Filename | Type | Purpose | Description |
| --- | --- | --- | --- |
| `tests/makefile_core.bats` | Test suite | Core utilities | Validates `create-network` and `check-validity` success/failure branches. |
| `tests/makefile_groups.bats` | Test suite | Group orchestration | Covers make/yaml backends, group lifecycle commands, aliases, and error paths. |
| `tests/makefile_app_commands.bats` | Test suite | App command wiring | Table-driven assertions for per-app `docker compose` argument construction (simple and multi-file patterns). |
| `tests/makefile_aggregates.bats` | Test suite | Meta-target orchestration | Verifies `up-base`, `down-base`, `recreate-base`, `up-all`, and `down-all`, including sequencing checks. |
| `tests/test_helper.bash` | Helper | Unit-like harness | Creates isolated temp workspace, injects mocks, normalizes line endings, and provides common assertions/helpers. |
| `tests/integration/makefile_base_integration.bats` | Test suite | Base integration lifecycle | End-to-end integration checks for `create-network`, `check-validity`, `up-base`, `down-base`, and `recreate-base`. |
| `tests/integration/makefile_app_integration.bats` | Test suite | App integration lifecycle | Real-Docker container lifecycle tests for representative apps covering three patterns: blinko (simple), infra-postgres (infrastructure/database), freqtrade-postgres (multi-file with build). |
| `tests/integration/test_helper_integration.bash` | Helper | Integration harness | Provides opt-in gating, Docker availability checks, conflict-safe skips, and health wait utilities. |
| `tests/helpers/mock-bin/docker` | Mock binary | Docker simulation | Captures docker command arguments and supports controllable failure modes used by unit-like tests. |
| `tests/helpers/mock-bin/yq` | Mock binary | YAML parsing simulation | Minimal `yq` behavior required for YAML group backend unit-like test scenarios. |

## Notes

- Unit-like tests use mocked `docker` and `yq` binaries under `tests/helpers/mock-bin`.
- Unit-like tests run in a temporary workspace to avoid touching real files.
- Integration tests run against real Docker resources and are gated by `RUN_INTEGRATION=1`.
- Integration tests skip disruptive lifecycle checks when target base containers already exist.
- **Integration tests are slow**: App lifecycle tests (phase 4) involve container startup and healthcheck waits (30-180s per test). On slower systems or with containers taking longer to become healthy, tests may timeout or require manual intervention.
- Coverage includes:
	- Group command lifecycle and backend behavior (`init-groups`, `clean-groups`, `list-groups`, `up/down-group-*`, aliases)
	- Core utility commands (`create-network`, `check-validity`)
	- Aggregate orchestration targets (`up-base`, `down-base`, `recreate-base`, `up-all`, `down-all`) in unit-like layer
	- Table-driven per-app command construction assertions (simple and multi-file compose patterns)
	- Base lifecycle integration checks for phase 1-3 (`up-base`, `down-base`, `recreate-base`)
	- App lifecycle integration checks for phase 4 covering three representative patterns:
		- **Simple pattern** (stateless): blinko
		- **Infrastructure pattern** (database/stateful): infra-postgres with PostgreSQL healthcheck validation
		- **Multi-file pattern** (build + compose): freqtrade-postgres with Dockerfile build and state persistence
- On Windows/WSL repos, line endings can break mock executables (`bash\r`).
	The unit-like test helper normalizes line endings automatically during setup.
