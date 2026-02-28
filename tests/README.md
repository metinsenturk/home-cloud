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

## Notes

- `docker` and `yq` are mocked under `tests/helpers/mock-bin`.
- Tests run in a temporary workspace to avoid touching real files.
- Scope includes group commands and core utility commands (`create-network`, `check-validity`).
- On Windows/WSL repos, line endings can break mock executables (`bash\r`).
	The test helper normalizes line endings automatically during setup.
