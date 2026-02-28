#!/usr/bin/env python3
"""Check the active Freqtrade database backend and basic database health.

This script is intended to run on the **host machine** (WSL/Linux/macOS shell),
not inside a container. It inspects your running Docker containers and reports
which database backend Freqtrade is actively using.

Requirements
------------
1. Python 3.9+ on the host.
2. Docker CLI available on the host (`docker` command).
3. Running `freqtrade` container.
4. If backend is PostgreSQL:
   - Running `freqtrade_postgres` container.
   - `psql` available inside that container (true for official postgres image).
5. If backend is SQLite:
   - `sqlite3` available inside `freqtrade` container.

What this script does
---------------------
1. Checks that `freqtrade` container is running.
2. Reads `FREQTRADE__DB_URL` from container environment.
3. Detects backend from URL scheme:
   - `postgresql://...`
   - `sqlite://...`
4. Runs backend-specific checks:
   - PostgreSQL: session info, table list, `trades` row count, `orders` row count.
   - SQLite: table list, `trades` row count, `orders` row count.

Usage
-----
From repository root:

    python3 apps/freqtrade/check_database.py

From app directory:

    cd apps/freqtrade
    python3 check_database.py

Expected output (PostgreSQL)
----------------------------
    === Freqtrade Database Check ===
    Backend: PostgreSQL
    DB URL : postgresql://postgres:***@freqtrade-postgres:5432/freqtrade
    [Session]
    ...

Manual command equivalents (for debugging)
------------------------------------------
Read active DB URL:

    docker exec freqtrade sh -lc 'echo "$FREQTRADE__DB_URL"'

Run a psql query in postgres container:

    docker exec freqtrade_postgres sh -lc \
      'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT count(*) FROM trades;"'

List tables in sqlite database:

    docker exec freqtrade sh -lc \
      'sqlite3 /freqtrade/user_data/tradesv3.sqlite ".tables"'

Exit codes
----------
- 0: Success (checks completed)
- 1: Failure (container missing, backend unsupported, or query error)
"""

from __future__ import annotations

import re
import subprocess
import sys
from typing import Tuple

FREQTRADE_CONTAINER = "freqtrade"
POSTGRES_CONTAINER = "freqtrade_postgres"
SQLITE_PATH = "/freqtrade/user_data/tradesv3.sqlite"


def run(command: list[str]) -> Tuple[int, str, str]:
    """Run a host-side command and capture output.

    Args:
        command: Command and arguments as a list, e.g.
            ["docker", "ps", "--format", "{{.Names}}"].

    Returns:
        A tuple of:
        - exit_code: Process return code (0 = success)
        - stdout: Standard output with leading/trailing whitespace stripped
        - stderr: Standard error with leading/trailing whitespace stripped

    Notes:
        This helper never raises on non-zero exit codes. Callers decide how to
        handle failures and present user-friendly errors.
    """
    # capture_output=True lets us print friendly error messages instead of
    # raising an exception immediately on command failures.
    process = subprocess.run(command, capture_output=True, text=True)
    return process.returncode, process.stdout.strip(), process.stderr.strip()


def docker_exec(container: str, shell_command: str) -> Tuple[int, str, str]:
    """Execute a shell command in a running Docker container.

    Args:
        container: Container name (e.g., "freqtrade", "freqtrade_postgres").
        shell_command: Command string executed by `sh -lc` inside container.

    Returns:
        Same tuple contract as :func:`run`:
        (exit_code, stdout, stderr).

    Why `sh -lc`:
        - Enables environment variable expansion (`$POSTGRES_USER`, etc.)
        - Provides consistent shell parsing for quoted SQL commands
    """
    # Pattern used everywhere in this script:
    # docker exec <container> sh -lc "<command>"
    # `sh -lc` gives consistent shell parsing and env-var expansion.
    return run(["docker", "exec", container, "sh", "-lc", shell_command])


def container_running(name: str) -> bool:
    """Check whether a container is currently running.

    Args:
        name: Exact Docker container name.

    Returns:
        True if the container appears in `docker ps` output, otherwise False.

    Notes:
        - Only running containers are considered (`docker ps`).
        - If Docker command fails, returns False.
    """
    # We only check running containers (docker ps), not stopped ones (docker ps -a).
    code, output, _ = run(["docker", "ps", "--format", "{{.Names}}"])
    if code != 0:
        return False
    return name in output.splitlines()


def get_db_url() -> str:
    """Fetch the effective Freqtrade DB URL from container environment.

    Returns:
        Value of `FREQTRADE__DB_URL` from the running `freqtrade` container.

    Raises:
        RuntimeError: If command execution fails or variable is empty.

    Rationale:
        `FREQTRADE__DB_URL` is the final backend source-of-truth for this check.
        It reflects what the running process is configured to use.
    """
    # FREQTRADE__DB_URL is set via docker-compose environment and reflects the
    # effective DB backend in use by Freqtrade.
    code, output, err = docker_exec(FREQTRADE_CONTAINER, 'echo "$FREQTRADE__DB_URL"')
    if code != 0 or not output:
        details = err or "FREQTRADE__DB_URL is empty"
        raise RuntimeError(f"Could not read DB URL from container '{FREQTRADE_CONTAINER}': {details}")
    return output


def check_postgres(db_url: str) -> int:
    """Run PostgreSQL backend checks and print diagnostic output.

    Args:
        db_url: Effective DB URL printed for visibility.

    Returns:
        0 on success, 1 on failure.

    Checks performed:
        1. Confirms `freqtrade_postgres` container is running.
        2. Executes session query (`current_database`, `current_user`).
        3. Lists public schema tables.
        4. Counts rows in `trades` and `orders`.
    """
    print("Backend: PostgreSQL")
    print(f"DB URL : {db_url}")

    if not container_running(POSTGRES_CONTAINER):
        print(f"ERROR: '{POSTGRES_CONTAINER}' is not running.")
        return 1

    queries = [
        # Validate session/identity and current DB.
        ('SELECT current_database() AS database, current_user AS username;', "Session"),
        # Show all public tables so we can confirm schema exists.
        (
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema='public' ORDER BY table_name;",
            "Tables",
        ),
        # Core Freqtrade data checks.
        ('SELECT count(*) AS trades_count FROM "trades";', "Trades Count"),
        ('SELECT count(*) AS orders_count FROM "orders";', "Orders Count"),
    ]

    for sql, title in queries:
        print(f"\n[{title}]")
        # We intentionally rely on container env variables POSTGRES_USER/DB
        # instead of hardcoding credentials.
        command = 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c ' + repr(sql)
        code, output, err = docker_exec(POSTGRES_CONTAINER, command)
        if code != 0:
            print(f"ERROR: {err or 'psql command failed'}")
            return 1
        print(output)

    return 0


def check_sqlite(db_url: str) -> int:
    """Run SQLite backend checks and print diagnostic output.

    Args:
        db_url: Effective DB URL printed for visibility.

    Returns:
        0 on success, 1 on failure.

    Checks performed:
        1. Lists SQLite tables via `.tables`.
        2. Counts rows in `trades`.
        3. Counts rows in `orders`.
    """
    print("Backend: SQLite")
    print(f"DB URL : {db_url}")

    sql_queries = [
        # List available tables in sqlite DB file.
        (".tables", "Tables"),
        # Core Freqtrade data checks.
        ('SELECT count(*) AS trades_count FROM trades;', "Trades Count"),
        ('SELECT count(*) AS orders_count FROM orders;', "Orders Count"),
    ]

    for sql, title in sql_queries:
        print(f"\n[{title}]")
        # sqlite3 is executed inside freqtrade container against mounted DB file.
        command = f"sqlite3 {SQLITE_PATH} {repr(sql)}"
        code, output, err = docker_exec(FREQTRADE_CONTAINER, command)
        if code != 0:
            print(f"ERROR: {err or 'sqlite3 command failed'}")
            return 1
        print(output)

    return 0


def detect_backend(db_url: str) -> str:
    """Detect backend type from SQLAlchemy-style DB URL.

    Args:
        db_url: URL such as `postgresql://...` or `sqlite:///...`.

    Returns:
        One of:
        - "postgresql"
        - "sqlite"
        - extracted scheme (e.g., "mysql")
        - "unknown" if scheme cannot be parsed
    """
    normalized = db_url.lower().strip()
    if normalized.startswith("postgresql://"):
        return "postgresql"
    if normalized.startswith("sqlite://"):
        return "sqlite"

    match = re.match(r"^([a-z0-9_+.-]+)://", normalized)
    backend = match.group(1) if match else "unknown"
    return backend


def main() -> int:
    """Program entry point.

    Returns:
        Process-compatible exit code:
        - 0 when backend checks complete successfully
        - 1 when prerequisites fail or checks error

    Flow:
        1. Validate `freqtrade` container is running.
        2. Read active DB URL from container env.
        3. Detect backend and dispatch to corresponding checker.
    """
    # Fail early if the main app container is not running.
    if not container_running(FREQTRADE_CONTAINER):
        print(f"ERROR: '{FREQTRADE_CONTAINER}' container is not running.")
        print("Start it first with: make up-freqtrade or make up-freqtrade-postgres")
        return 1

    try:
        db_url = get_db_url()
    except RuntimeError as error:
        print(f"ERROR: {error}")
        return 1

    backend = detect_backend(db_url)
    print("=== Freqtrade Database Check ===")

    if backend == "postgresql":
        return check_postgres(db_url)

    if backend == "sqlite":
        return check_sqlite(db_url)

    print(f"ERROR: Unsupported/unknown backend from DB URL: {db_url}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
