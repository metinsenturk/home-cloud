# Makefile Unit-like Tests

These tests validate Makefile command logic without running real Docker services.

## Requirements

- `bash`
- `make`
- `bats` (bats-core)

## Run tests

```bash
bats tests/makefile_groups.bats
```

or

```bash
make test-makefile
```

## Notes

- `docker` and `yq` are mocked under `tests/helpers/mock-bin`.
- Tests run in a temporary workspace to avoid touching real files.
- Scope focuses on group commands (`list-groups`, `up-group-*`, `down-group-*`, `init-groups`, `clean-groups`, aliases).
