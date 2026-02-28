# Custom Scripts and Automation

This Freqtrade deployment includes runtime and host-side helper scripts:

## 1. entrypoint.py

**Purpose**: Automatic initialization override that runs before freqtrade launches.

**File**: [entrypoint.py](entrypoint.py)

**What it does:**
- Checks if `config.json` exists
- If missing, runs automatic first-time setup:
  1. Creates user directory structure (`freqtrade create-userdir`)
  2. Generates default `config.json` (`freqtrade new-config`)
  3. Patches exchange from Binance → Kraken (avoids geo-blocking)
  4. Optionally downloads official strategies (if enabled)
- Launches freqtrade with the initialized config

**Key Functions:**
- `initialize_if_needed()` - Orchestrates all setup steps
- `create_user_directory()` - Runs `freqtrade create-userdir`
- `generate_config()` - Runs `freqtrade new-config` with piped input
- `update_exchange_to_kraken()` - Patches config.json JSON to switch exchanges
- `download_strategies()` - Calls strategy downloader (see below)

**Module Variables** (can be modified in the script):
```python
ENABLE_STRATEGY_DOWNLOAD = True  # Enable/disable official strategy downloads
USER_DATA_DIR = Path("/freqtrade/user_data")  # Container user data path
CONFIG_FILE = USER_DATA_DIR / "config.json"   # Config location
```

**How to customize:**
- Edit [entrypoint.py](entrypoint.py) directly in the image mount
- Change `ENABLE_STRATEGY_DOWNLOAD = False` to disable automatic strategy downloads
- Changes take effect on next container start

## 2. strategy_downloader.py

**Purpose**: Optional automation to download official freqtrade strategies from GitHub.

**File**: [strategy_downloader.py](strategy_downloader.py)

**What it does:**
1. Checks if custom strategies already exist (skips if they do)
2. Downloads the [freqtrade-strategies](https://github.com/freqtrade/freqtrade-strategies) repository as ZIP
3. Extracts the ZIP to `/tmp/`
4. Copies all strategy files (.py) and helper folders (indicators, etc.) to `user_data/strategies/`
5. Cleans up temporary files

**Why use this?**
- Official strategies are well-tested and maintained by the freqtrade team
- Includes helper modules and custom indicator definitions
- Provides reference implementations for developing your own strategies
- Non-destructive: existing custom strategies are not overwritten
- Can be toggled via module flags

**Module Variables** (can be modified):
```python
ENABLE_STRATEGY_DOWNLOAD = True  # Toggle in entrypoint.py to enable/disable
FORCE_DOWNLOAD_STRATEGIES = False  # Set to True to re-download and overwrite strategies
REPO_STRATEGIES_RELATIVE_PATH = Path("user_data/strategies")  # Repo structure path
REPO_ZIP_URL = "https://github.com/freqtrade/freqtrade-strategies/archive/refs/heads/main.zip"
```

### Force Re-download Strategies

Edit [strategy_downloader.py](strategy_downloader.py) and change:
```python
FORCE_DOWNLOAD_STRATEGIES = True  # Forces download even if strategies exist
```

Then restart the container. On startup, it will download the latest official strategies and overwrite all existing ones.

### Disable Strategy Downloads

Edit [entrypoint.py](entrypoint.py) and change:
```python
ENABLE_STRATEGY_DOWNLOAD = False  # Skips strategy downloads during initialization
```

## 3. check_database.py

**Purpose**: Verify which database backend Freqtrade is currently using (**PostgreSQL** or **SQLite**) and run lightweight health/data checks.

**File**: [check_database.py](check_database.py)

### Where this script runs

This script is designed to run on the **host machine** (your WSL shell / terminal), **not inside the container**.

- ✅ Run from host: `python3 apps/freqtrade/check_database.py`
- ❌ Do not run inside `freqtrade` container as primary workflow

Why host-side?
- The script orchestrates Docker CLI calls (`docker ps`, `docker exec`) to inspect containers.
- It must be able to talk to the Docker daemon from outside the target containers.

### What it checks

1. Confirms `freqtrade` container is running.
2. Reads active DB URL from container env: `FREQTRADE__DB_URL`.
3. Detects backend from URL:
         - `postgresql://...` → PostgreSQL branch
         - `sqlite://...` → SQLite branch
4. Runs backend-specific checks:
         - PostgreSQL: connection session, table list, row counts (`trades`, `orders`)
         - SQLite: table list and row counts from `tradesv3.sqlite`

### How to run

From repository root:

```bash
python3 apps/freqtrade/check_database.py
```

Optional (from app folder):

```bash
cd apps/freqtrade
python3 check_database.py
```

### Command anatomy (what the script executes)

The script uses `docker exec <container> sh -lc "..."` to run shell commands inside containers.

#### 1) Read active DB URL from freqtrade container

```bash
docker exec freqtrade sh -lc 'echo "$FREQTRADE__DB_URL"'
```

- `docker exec freqtrade`: run command in running `freqtrade` container
- `sh -lc`: run in shell with login-style command parsing
- `echo "$FREQTRADE__DB_URL"`: prints effective DB URL currently used by the bot

#### 2) PostgreSQL checks via psql

Session check:

```bash
docker exec freqtrade_postgres sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT current_database(), current_user;"'
```

Table list:

```bash
docker exec freqtrade_postgres sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT table_name FROM information_schema.tables WHERE table_schema=\'public\' ORDER BY table_name;"'
```

Trades count:

```bash
docker exec freqtrade_postgres sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT count(*) FROM trades;"'
```

Notes on `psql` flags:
- `-U`: PostgreSQL username
- `-d`: database name
- `-c`: execute one SQL statement and exit

#### 3) SQLite checks via sqlite3

```bash
docker exec freqtrade sh -lc 'sqlite3 /freqtrade/user_data/tradesv3.sqlite ".tables"'
docker exec freqtrade sh -lc 'sqlite3 /freqtrade/user_data/tradesv3.sqlite "SELECT count(*) FROM trades;"'
```

### Example output

```text
=== Freqtrade Database Check ===
Backend: PostgreSQL
DB URL : postgresql://postgres:postgres@freqtrade-postgres:5432/freqtrade

[Session]
database  | username
-----------+----------
freqtrade | postgres

[Trades Count]
trades_count
------------
3
```

### Exit behavior

- Exit code `0`: checks passed
- Exit code `1`: container missing, unsupported backend, or query failure

This makes it suitable for automation (CI checks, scripts, cron wrappers).

### Troubleshooting

- **`freqtrade` container is not running**
        - Start stack first: `make up-freqtrade` or `make up-freqtrade-postgres`

- **`freqtrade_postgres` not running while backend is PostgreSQL**
        - Start PostgreSQL stack: `make up-freqtrade-postgres`

- **`psql command failed`**
        - Check Postgres logs: `docker logs freqtrade_postgres`
        - Verify DB env vars in `apps/freqtrade/.env`

- **`sqlite3 command failed`**
        - Ensure SQLite DB file exists at `/freqtrade/user_data/tradesv3.sqlite`
        - Check freqtrade logs: `docker logs freqtrade`


## Initialization Flow Diagram

On **first container start**, this is the complete execution flow:

```
Docker Container Start
        ↓
entrypoint.py invoked
        ↓
Check if config.json exists?
        ↓
    [NO]  →  First-Time Setup:
             1. Create user directory
             2. Generate config.json
             3. Patch exchange to Kraken
             4. Download strategies (if ENABLE_STRATEGY_DOWNLOAD=True)
             5. Log "[entrypoint] First-time setup complete"
        ↓
    [YES] →  Log "[entrypoint] config.json found. Skipping initialization"
        ↓
Launch freqtrade with command from docker-compose.yml
        ↓
FreqUI available at https://freqtrade.${DOMAIN}
```

## First-Start Logs Example

Here's what you'll see during the first container startup:

```
[entrypoint] config.json not found. Running first-time setup...
[entrypoint] Running: Creating user directory structure...
[entrypoint] Generating config.json with defaults...
[entrypoint] Updating exchange to kraken...
[entrypoint] Switched exchange from binance to kraken
[strategy-downloader] Downloading official freqtrade strategies...
[strategy-downloader] Fetching repository...
[strategy-downloader] Extracting strategies...
[strategy-downloader] Copying 25 strategy files and 3 folders...
[strategy-downloader]   ✓ Copied sample_strategy.py
[strategy-downloader]   ✓ Copied adx_strategy.py
... (more files)
[strategy-downloader] Successfully installed 25 strategy files and 3 folders
[entrypoint] First-time setup complete.
[entrypoint] Starting freqtrade...
```

## Subsequent Starts

On container restarts (when `config.json` already exists):

```
[entrypoint] config.json found at /freqtrade/user_data/config.json. Skipping initialization.
[entrypoint] Starting freqtrade...
```

No re-initialization happens—the bot starts immediately with your existing configuration.

## Customization Guide

### Modify Exchange

To change the default exchange from Kraken to something else (e.g., Binance), edit `user_data/config.json` after first startup:

```json
{
  "exchange": {
    "name": "binance",
    ...
  }
}
```

Then restart the container. The entrypoint runs `create-userdir` only on each startup if config.json doesn't exist.

### Add Custom Initialization Steps

To add custom setup code (e.g., configure API keys, set trading pairs), edit [entrypoint.py](entrypoint.py) and add logic to the `initialize_if_needed()` function before the `log("First-time setup complete.")` line.

### Disable Automatic Initialization Entirely

Edit [entrypoint.py](entrypoint.py) and change:
```python
ENABLE_STRATEGY_DOWNLOAD = False
```

Also wrap the `initialize_if_needed()` call in `main()` with a conditional:
```python
# Skip initialization for testing
if False:
    initialize_if_needed()
```

This allows experimenting without automatic setup on every container start.
