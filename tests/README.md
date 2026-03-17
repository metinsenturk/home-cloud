# Makefile Tests (Unit-like + Integration)

This directory contains both:
- Unit-like tests (mocked Docker/yq, fast and safe by default)
- Integration tests (real Docker daemon, opt-in)

## Requirements

- `bash`
- `make`
- `bats` (bats-core) - required
- `GNU parallel` or `rush` (optional) - for parallel test execution with `--jobs` flag

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

## Install GNU parallel (optional - for parallel test execution)

For parallel test execution in CI pipelines (faster quick tier testing), install `GNU parallel`:

### Ubuntu / WSL

```bash
sudo apt-get update
sudo apt-get install -y parallel
```

### macOS (Homebrew)

```bash
brew install parallel
```

### Verify install

```bash
parallel --version
```

If `GNU parallel` is not installed, `BATS_PARALLEL=1` or `--jobs` flag will be silently ignored and tests run sequentially (no error).

## Validate dependencies

Check which testing tools are available on your system:

```bash
make check-tools
```

This command displays:
- **Required tools:** `docker`, `docker compose`, `make`, `bash` (must be present)
- **Optional tools:** `bats`, `GNU parallel`, `yq`, `git` (helpful but not blocking)

Example output:
```
✔ docker: /usr/bin/docker
✔ make: /usr/bin/make
✔ bash: /usr/bin/bash
✔ bats: /usr/bin/bats
✘ parallel: not found (optional - needed for BATS_PARALLEL=1)
✘ yq: not found (optional)
✔ git: /usr/bin/git
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

### Performance Analysis: Container Startup Timing

When running full integration tests, you can collect timing data to identify which apps are slow on your system. This helps tune timeout values and understand hardware-specific performance.

```bash
# Collect startup times for each container
INTEGRATION_TIMING_REPORT=1 RUN_INTEGRATION=1 make test-makefile-integration-full
```

Output example:
```
⏱️  'blinko' healthy in 8s
⏱️  'infra_postgres' healthy in 12s
⏱️  'freqtrade' healthy in 45s
```

**Interpreting results:**
- **< 10s**: Fast, typical for stateless apps
- **10-30s**: Normal, typical for databases with initialization
- **30-60s+**: Slow, consider increasing `INTEGRATION_TEST_TIMEOUT_SLOW` on slow systems

**For slow system tuning:**

```bash
# Collect timing on your hardware
INTEGRATION_TIMING_REPORT=1 RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=full \
  make test-makefile-integration-full 2>&1 | grep "⏱️"

# Then adjust timeouts for your system
INTEGRATION_TEST_TIMEOUT=300 INTEGRATION_TEST_TIMEOUT_SLOW=600 \
  INTEGRATION_TIMING_REPORT=1 RUN_INTEGRATION=1 \
  make test-makefile-integration-full
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

### Parallel Test Execution (CI Optimization)

For faster test feedback in CI pipelines, parallel execution can be used selectively. Requires `GNU parallel` installed (or `rush`).

**Prerequisites for parallel execution:**

```bash
# Install GNU parallel for --jobs support
sudo apt-get install -y parallel  # Ubuntu/WSL
# or
brew install parallel  # macOS
```

If `GNU parallel` is not installed, `BATS_PARALLEL=1` will be silently ignored and tests run sequentially.

**Unit-like tests (sequential recommended for current setup):**

Currently the unit-like tests have setup/teardown logic that doesn't safely parallelize. Sequential execution is recommended:

```bash
make test-makefile  # Sequential, safe, ~15-20s
```

**Integration quick tier (safe to parallelize - sanity checks only):**

Quick tier tests are independent sanity checks with no container lifecycle, making them safe to run in parallel:

```bash
# Run 2 jobs in parallel for quick sanity checks
BATS_PARALLEL=1 RUN_INTEGRATION=1 make test-makefile-integration-quick
```

**⚠️ Integration full tier (NOT recommended for parallel execution):**

Full integration tests with container lifetimes are **not safe to parallelize** due to:
- Shared Docker daemon and containers (port conflicts)
- Resource contention (memory/CPU for multiple concurrent startups)
- Healthcheck synchronization issues

```bash
# DON'T do this (will cause timeouts or conflicts):
# BATS_PARALLEL=1 RUN_INTEGRATION=1 make test-makefile-integration-full

# DO run full tier sequentially:
RUN_INTEGRATION=1 make test-makefile-integration-full
```

**CI Pipeline Recommended:**

```bash
# Sequential unit tests (safe, ~15-20s)
make test-makefile

# Quick integration sanity checks in parallel (safe, ~30-60s)
BATS_PARALLEL=1 RUN_INTEGRATION=1 make test-makefile-integration-quick

# Full integration sequentially (deep validation, 3-5 minutes)
RUN_INTEGRATION=1 RUN_INTEGRATION_TIER=full make test-makefile-integration-full
```

## Test Files

| Filename | Type | Purpose | Description |
| --- | --- | --- | --- |
| `tests/makefile_core.bats` | Test suite | Core utilities | Validates `create-network` and `check-validity` success/failure branches. |
| `tests/makefile_groups.bats` | Test suite | Group orchestration | Covers make/yaml backends, group lifecycle commands, aliases, and error paths. |
| `tests/makefile_app_commands.bats` | Test suite | App command wiring | Table-driven assertions for per-app `docker compose` argument construction (simple and multi-file patterns). |
| `tests/makefile_aggregates.bats` | Test suite | Meta-target orchestration | Verifies `up-base`, `down-base`, `recreate-base`, `up-all`, and `down-all`, including sequencing checks. |
| `tests/test_helper.bash` | Helper | Unit-like harness | Creates isolated temp workspace, injects mocks, normalizes line endings, and provides common assertions/helpers. |
| `tests/integration/makefile_base_integration.bats` | Test suite | Base integration lifecycle | End-to-end integration checks for `create-network`, `check-validity`, `up-base`, `down-base`, and `recreate-base`. |
| `tests/integration/makefile_app_integration.bats` | Test suite | App integration lifecycle | Real-Docker container lifecycle tests for representative apps covering three patterns: blinko (simple), postgres (infrastructure/database), freqtrade-postgres (multi-file with build). |
| `tests/integration/test_helper_integration.bash` | Helper | Integration harness | Provides opt-in gating, Docker availability checks, conflict-safe skips, and health wait utilities. |
| `tests/helpers/mock-bin/docker` | Mock binary | Docker simulation | Captures docker command arguments and supports controllable failure modes used by unit-like tests. |
| `tests/helpers/mock-bin/yq` | Mock binary | YAML parsing simulation | Minimal `yq` behavior required for YAML group backend unit-like test scenarios. |

## Notes

- Unit-like tests use mocked `docker` and `yq` binaries under `tests/helpers/mock-bin`.
- Unit-like tests run in a temporary workspace to avoid touching real files.
- Integration tests run against real Docker resources and are gated by `RUN_INTEGRATION=1`.
- Integration tests skip disruptive lifecycle checks when target base containers already exist.
- **Integration tests are slow**: App lifecycle tests (phase 4) involve container startup and healthcheck waits (30-180s per test). On slower systems or with containers taking longer to become healthy, tests may timeout or require manual intervention.
- **Performance diagnostics**: Use `INTEGRATION_TIMING_REPORT=1` to collect startup times for each container. Identify slow apps and tune `INTEGRATION_TEST_TIMEOUT` variables accordingly.
- Coverage includes:
	- Group command lifecycle and backend behavior (`init-groups`, `clean-groups`, `list-groups`, `up/down-group-*`, aliases)
	- Core utility commands (`create-network`, `check-validity`)
	- Aggregate orchestration targets (`up-base`, `down-base`, `recreate-base`, `up-all`, `down-all`) in unit-like layer
	- Table-driven per-app command construction assertions (simple and multi-file compose patterns)
	- Base lifecycle integration checks for phase 1-3 (`up-base`, `down-base`, `recreate-base`)
	- App lifecycle integration checks for phase 4 covering three representative patterns:
		- **Simple pattern** (stateless): blinko
		- **Infrastructure pattern** (database/stateful): postgres with PostgreSQL healthcheck validation
		- **Multi-file pattern** (build + compose): freqtrade-postgres with Dockerfile build and state persistence
- On Windows/WSL repos, line endings can break mock executables (`bash\r`).
	The unit-like test helper normalizes line endings automatically during setup.
