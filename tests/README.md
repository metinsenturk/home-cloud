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

```bash
RUN_INTEGRATION=1 bats tests/integration/*.bats
```

or

```bash
make test-makefile-integration RUN_INTEGRATION=1
```

### All tests

```bash
make test-makefile-all
```

Enable integration layer during all-tests run:

```bash
make test-makefile-all RUN_INTEGRATION=1
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
| `tests/integration/makefile_app_integration.bats` | Test suite | App integration lifecycle | Real-Docker container lifecycle tests for representative apps (blinko simple pattern, freqtrade-postgres multi-file pattern). |
| `tests/integration/test_helper_integration.bash` | Helper | Integration harness | Provides opt-in gating, Docker availability checks, conflict-safe skips, and health wait utilities. |
| `tests/helpers/mock-bin/docker` | Mock binary | Docker simulation | Captures docker command arguments and supports controllable failure modes used by unit-like tests. |
| `tests/helpers/mock-bin/yq` | Mock binary | YAML parsing simulation | Minimal `yq` behavior required for YAML group backend unit-like test scenarios. |

## Notes

- Unit-like tests use mocked `docker` and `yq` binaries under `tests/helpers/mock-bin`.
- Unit-like tests run in a temporary workspace to avoid touching real files.
- Integration tests run against real Docker resources and are gated by `RUN_INTEGRATION=1`.
- Integration tests skip disruptive lifecycle checks when target base containers already exist.
- Coverage includes:
	- Group command lifecycle and backend behavior (`init-groups`, `clean-groups`, `list-groups`, `up/down-group-*`, aliases)
	- Core utility commands (`create-network`, `check-validity`)
	- Aggregate orchestration targets (`up-base`, `down-base`, `recreate-base`, `up-all`, `down-all`) in unit-like layer
	- Table-driven per-app command construction assertions (simple and multi-file compose patterns)
	- Base lifecycle integration checks for phase 1-3 (`up-base`, `down-base`, `recreate-base`)
	- App lifecycle integration checks for phase 4 (simple pattern: blinko; multi-file pattern: freqtrade-postgres)
- On Windows/WSL repos, line endings can break mock executables (`bash\r`).
	The unit-like test helper normalizes line endings automatically during setup.
