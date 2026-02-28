# PostgreSQL Setup for Freqtrade

This guide explains how to use PostgreSQL instead of SQLite as the database backend for Freqtrade.

## Quick Start

```bash
# Start freqtrade with PostgreSQL (from root folder)
make up-freqtrade-postgres

# Stop freqtrade with PostgreSQL
make down-freqtrade-postgres

# Rebuild the custom image (after base image updates)
make build-freqtrade
```

## Architecture

The PostgreSQL setup consists of:

1. **Custom Docker Image** (`Dockerfile`)
   - Extends `freqtradeorg/freqtrade:latest`
   - Adds `psycopg2-binary` Python package for PostgreSQL connectivity
   - Metadata labels for identification

2. **PostgreSQL Service** (`docker-compose.postgres.yml`)
   - PostgreSQL 16 Alpine (lightweight, production-ready)
   - Dedicated data volume (`home_freqtrade_postgres_data`)
   - Health checks to ensure database is ready before freqtrade starts

3. **Override Configuration** (`docker-compose.postgres.yml`)
   - Replaces SQLite database URL with PostgreSQL connection string
   - Adds `depends_on` to wait for database health check
   - Builds custom image automatically on first run

## Files Structure

```
apps/freqtrade/
├── Dockerfile                      # Custom image definition with psycopg2-binary
├── docker-compose.yml              # Base configuration (SQLite)
├── docker-compose.postgres.yml     # PostgreSQL overrides
├── entrypoint.py                   # Auto-initialization script
├── strategy_downloader.py          # Strategy fetcher
├── .env                            # Local environment variables
└── POSTGRES.md                     # This file
```

## How It Works

### Docker Compose Override Pattern

The setup uses Docker Compose's multiple file feature:

```bash
docker compose \
   -f docker-compose.yml \
   -f docker-compose.postgres.yml \
  up -d
```

**What gets overridden:**
- `freqtrade.image` → `freqtrade.build` (builds custom image)
- `FREQTRADE__DB_URL` → PostgreSQL connection string
- Adds `freqtrade-postgres` service
- Adds `depends_on` health check dependency

**What stays the same:**
- All other environment variables (API, Telegram, etc.)
- Volume mounts (user_data, scripts)
- Network configuration
- Traefik labels and routing

### First Run Behavior

When you run `make up-freqtrade-postgres` for the first time:

1. **Image Build** (~30-60 seconds)
   - Pulls `freqtradeorg/freqtrade:latest`
   - Installs `psycopg2-binary`
   - Creates a local custom image for the `freqtrade` service

2. **PostgreSQL Initialization** (~10 seconds)
   - Creates `home_freqtrade_postgres_data` volume
   - Initializes database with credentials from `.env`
   - Runs health check until `pg_isready` succeeds

3. **Freqtrade Initialization** (~5-10 seconds)
   - Waits for PostgreSQL health check to pass
   - Runs `entrypoint.py` auto-initialization
   - Creates `config.json`, downloads strategies (if enabled)
   - Connects to PostgreSQL and creates tables
   - Starts trading bot

**Total first-run time:** ~45-80 seconds  
**Subsequent runs:** ~5-10 seconds (image cached, database persisted)

## Configuration

### Required Environment Variables

Make sure these are set in `apps/freqtrade/.env`:

```bash
# PostgreSQL Database Configuration
FREQTRADE_POSTGRES_USER=freqtrade
FREQTRADE_POSTGRES_PASSWORD=your_secure_password_here
FREQTRADE_POSTGRES_DB=freqtrade

# API Server Credentials
FREQTRADE_API_USERNAME=freqtrader
FREQTRADE_API_PASSWORD=your_secure_password_here

# JWT and WebSocket Tokens
FREQTRADE_JWT_SECRET=generate_with_secrets_token_hex_32
FREQTRADE_WS_TOKEN=generate_with_secrets_token_hex_32

# Telegram (Optional)
FREQTRADE_TELEGRAM_ENABLED=false
FREQTRADE_TELEGRAM_TOKEN=
FREQTRADE_TELEGRAM_CHAT_ID=
```

**Generate secure tokens:**
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### Database Connection String

The connection string is automatically constructed:
```
postgresql://${FREQTRADE_POSTGRES_USER}:${FREQTRADE_POSTGRES_PASSWORD}@freqtrade-postgres:5432/${FREQTRADE_POSTGRES_DB}
```

Example with actual values:
```
postgresql://freqtrade:mypassword@freqtrade-postgres:5432/freqtrade
```

## Management Commands

### Starting and Stopping

```bash
# Start with PostgreSQL
make up-freqtrade-postgres

# Stop (containers only, data persists)
make down-freqtrade-postgres

# Stop and remove volumes (deletes all data!)
docker compose \
  --env-file .env \
  --env-file apps/freqtrade/.env \
  -f apps/freqtrade/docker-compose.yml \
  -f apps/freqtrade/docker-compose.postgres.yml \
  down -v
```

### Rebuilding the Image

Rebuild when:
- Freqtrade base image has updates
- You want to upgrade psycopg2-binary
- Dockerfile changes

```bash
# Rebuild with cache
make build-freqtrade

# Rebuild without cache (clean build)
docker compose \
  --env-file .env \
  --env-file apps/freqtrade/.env \
  -f apps/freqtrade/docker-compose.yml \
  -f apps/freqtrade/docker-compose.postgres.yml \
  build --no-cache --pull
```

### Database Management

**Connect to PostgreSQL:**
```bash
docker exec -it freqtrade_postgres psql -U freqtrade -d freqtrade
```

**Backup database:**
```bash
docker exec freqtrade_postgres pg_dump -U freqtrade freqtrade > backup.sql
```

**Restore database:**
```bash
cat backup.sql | docker exec -i freqtrade_postgres psql -U freqtrade -d freqtrade
```

**View tables:**
```bash
docker exec freqtrade_postgres psql -U freqtrade -d freqtrade -c "\dt"
```

**View active trades:**
```bash
docker exec freqtrade_postgres psql -U freqtrade -d freqtrade -c "SELECT * FROM trades WHERE is_open = true;"
```

## Comparison: SQLite vs PostgreSQL

| Feature | SQLite (Default) | PostgreSQL |
|---------|------------------|------------|
| **Setup Complexity** | Zero config | Requires separate service |
| **First Run Time** | ~5s | ~45-80s (one-time build) |
| **Performance** | Good for single bot | Better for high volume |
| **Concurrent Access** | Limited | Excellent |
| **Backup** | Copy `.sqlite` file | `pg_dump` / `pg_restore` |
| **External Tools** | Limited | Full SQL client support |
| **Disk Usage** | ~10-50 MB | ~50-200 MB |
| **Multi-Bot Setup** | One DB per bot | Shared DB possible |
| **Containerization** | Single container | Two containers |

## When to Use PostgreSQL

**Choose PostgreSQL if you:**
- ✅ Plan to run multiple freqtrade instances
- ✅ Need to query trade data from external tools (Metabase, Redash, etc.)
- ✅ Want centralized database management
- ✅ Need robust ACID compliance
- ✅ Require database replication/backups
- ✅ Have high trading volume (many pairs, short timeframes)

**Stick with SQLite if you:**
- ✅ Run a single bot instance
- ✅ Prefer simpler setup
- ✅ Trade casually or in dry-run mode
- ✅ Don't need external database access

## Troubleshooting

### Build Failures

**Error: `failed to solve with frontend dockerfile.v0`**
- **Cause:** Docker buildkit issue
- **Fix:** Update Docker to latest version or disable buildkit:
  ```bash
  export DOCKER_BUILDKIT=0
  make up-freqtrade-postgres
  ```

**Error: `Could not find a version that satisfies psycopg2-binary`**
- **Cause:** Network issue or PyPI unavailable
- **Fix:** Check internet connection, wait for PyPI to recover

### Connection Failures

**Error: `could not connect to server: Connection refused`**
- **Cause:** PostgreSQL not ready yet
- **Fix:** Wait 30s for health check, check logs:
  ```bash
  docker logs freqtrade_postgres
  ```

**Error: `FATAL: password authentication failed`**
- **Cause:** Wrong credentials in `.env`
- **Fix:** 
  1. Update `apps/freqtrade/.env` with correct password
  2. Rebuild: `make down-freqtrade-postgres && make up-freqtrade-postgres`

**Error: `FATAL: database "freqtrade" does not exist`**
- **Cause:** Database not initialized
- **Fix:** 
  ```bash
  docker exec -it freqtrade_postgres psql -U postgres -c "CREATE DATABASE freqtrade;"
  docker exec -it freqtrade_postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE freqtrade TO freqtrade;"
  ```

### Performance Issues

**Slow queries**
- Check database size: `docker exec freqtrade_postgres psql -U freqtrade -d freqtrade -c "SELECT pg_size_pretty(pg_database_size('freqtrade'));"`
- Vacuum database: `docker exec freqtrade_postgres psql -U freqtrade -d freqtrade -c "VACUUM ANALYZE;"`

**High disk usage**
- Review old trades and clean up:
  ```bash
  docker exec freqtrade_postgres psql -U freqtrade -d freqtrade -c "DELETE FROM trades WHERE close_date < NOW() - INTERVAL '90 days';"
  ```

## Switching Between SQLite and PostgreSQL

### SQLite → PostgreSQL (Migration)

1. **Export SQLite data:**
   ```bash
   docker exec freqtrade freqtrade db-export --db-url=sqlite:////freqtrade/user_data/tradesv3.sqlite --export-filename=/freqtrade/user_data/trades_export.json
   ```

2. **Start PostgreSQL setup:**
   ```bash
   make up-freqtrade-postgres
   ```

3. **Import data:**
   ```bash
   docker exec freqtrade freqtrade db-import --db-url=postgresql://... --import-filename=/freqtrade/user_data/trades_export.json
   ```

### PostgreSQL → SQLite (Rollback)

1. **Export PostgreSQL data:**
   ```bash
   docker exec freqtrade freqtrade db-export --db-url=postgresql://... --export-filename=/freqtrade/user_data/trades_export.json
   ```

2. **Stop PostgreSQL setup:**
   ```bash
   make down-freqtrade-postgres
   ```

3. **Start SQLite setup:**
   ```bash
   make up-freqtrade
   ```

4. **Import data:**
   ```bash
   docker exec freqtrade freqtrade db-import --db-url=sqlite:////freqtrade/user_data/tradesv3.sqlite --import-filename=/freqtrade/user_data/trades_export.json
   ```

## Security Considerations

1. **Strong Passwords**
   - Use `FREQTRADE_POSTGRES_PASSWORD` with at least 16 characters
   - Mix uppercase, lowercase, numbers, symbols

2. **Network Isolation**
   - PostgreSQL only accessible via `home_freqtrade_network` (private)
   - Never expose port 5432 to `home_network` (public)

3. **Backup Encryption**
   - Encrypt backups before storing externally:
     ```bash
     docker exec freqtrade_postgres pg_dump -U freqtrade freqtrade | gpg -e -r your@email.com > backup.sql.gpg
     ```

4. **Regular Updates**
   - Rebuild image monthly to get latest packages:
     ```bash
     make build-freqtrade
     ```

## Advanced: Using Infrastructure PostgreSQL

If you have `infra-postgres` running, you can share the database:

**Update `docker-compose.postgres.yml`:**
```yaml
services:
  freqtrade:
    networks:
      - home_network
      - home_infra_postgres_network  # Add this
    environment:
      FREQTRADE__DB_URL: postgresql://freqtrade:${INFRA_FREQTRADE_DB_PASSWORD}@infra-postgres:5432/freqtrade
```

**Create database in infra-postgres:**
```bash
docker exec -it infra_postgres psql -U postgres -c "CREATE DATABASE freqtrade;"
docker exec -it infra_postgres psql -U postgres -c "CREATE USER freqtrade WITH PASSWORD 'your_password';"
docker exec -it infra_postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE freqtrade TO freqtrade;"
```

**Benefits:**
- One less container
- Centralized database management
- Shared backup strategy

**Drawbacks:**
- Tight coupling with infrastructure
- Harder to move freqtrade independently

## Official Resources

- **Freqtrade Database Docs:** https://www.freqtrade.io/en/stable/utils/#database-management
- **PostgreSQL Docker Image:** https://hub.docker.com/_/postgres
- **psycopg2 Docs:** https://www.psycopg.org/docs/
