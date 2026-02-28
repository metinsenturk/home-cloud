# Makefile Unit-like Tests

These tests validate Makefile command logic without running real Docker services.

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

```bash
bats tests/*.bats
```

or

```bash
make test-makefile
```

## Test Files

| Filename | Type | Purpose | Description |
| --- | --- | --- | --- |
| `tests/makefile_core.bats` | Test suite | Core utilities | Validates `create-network` and `check-validity` success/failure branches. |
| `tests/makefile_groups.bats` | Test suite | Group orchestration | Covers make/yaml backends, group lifecycle commands, aliases, and error paths. |
| `tests/makefile_app_commands.bats` | Test suite | App command wiring | Table-driven assertions for per-app `docker compose` argument construction (simple and multi-file patterns). |
| `tests/makefile_aggregates.bats` | Test suite | Meta-target orchestration | Verifies `up-base`, `down-base`, `recreate-base`, `up-all`, and `down-all`, including sequencing checks. |
| `tests/test_helper.bash` | Helper | Shared test harness | Creates isolated temp workspace, injects mocks, normalizes line endings, and provides common assertions/helpers. |
| `tests/helpers/mock-bin/docker` | Mock binary | Docker simulation | Captures docker command arguments and supports controllable failure modes used by tests. |
| `tests/helpers/mock-bin/yq` | Mock binary | YAML parsing simulation | Minimal `yq` behavior required for YAML group backend test scenarios. |

## Notes

- `docker` and `yq` are mocked under `tests/helpers/mock-bin`.
- Tests run in a temporary workspace to avoid touching real files.
- Coverage includes:
	- Group command lifecycle and backend behavior (`init-groups`, `clean-groups`, `list-groups`, `up/down-group-*`, aliases)
	- Core utility commands (`create-network`, `check-validity`)
	- Aggregate orchestration targets (`up-base`, `down-base`, `recreate-base`, `up-all`, `down-all`)
	- Table-driven per-app command construction assertions (simple and multi-file compose patterns)
- On Windows/WSL repos, line endings can break mock executables (`bash\r`).
	The test helper normalizes line endings automatically during setup.
