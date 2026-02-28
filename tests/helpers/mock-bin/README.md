# Mock Binaries for Makefile Tests

This folder contains test-only mock executables that are injected into `PATH` by `tests/test_helper.bash`.

## Why this exists

The Makefile test suite validates command behavior (flow, exit codes, and error handling) without requiring real external dependencies.

Mocks allow tests to run quickly and deterministically without:
- a running Docker daemon
- a real `yq` installation

## Files

- `docker`: Mock Docker CLI that returns success for subcommands used by the Makefile (`network inspect`, `network create`, `compose`).
- `yq`: Minimal parser for the exact query forms used by group YAML tests.

## Scope and limitations

- These scripts are intentionally minimal and only support the patterns needed by the current tests.
- They are **not** full replacements for real `docker` or `yq`.
- If Makefile behavior changes (new command flags, new query formats), update mocks and tests together.
