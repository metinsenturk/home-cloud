# Redash

Redash is an open-source data visualization and query tool that allows you to connect to various data sources, write SQL queries, create visualizations, and build interactive dashboards.

## Services

| Service | Description |
|---------|-------------|
| `redash` | Main Redash server with web UI and API (Gunicorn on port 5000) |
| `redash-scheduler` | Handles scheduled query executions and job scheduling |
| `redash-worker` | Background job worker that processes query execution tasks |
| `postgres` | PostgreSQL database storing Redash metadata (users, dashboards, queries, etc.) |
| `redis` | Redis in-memory cache and job queue (RQ) for background tasks |

## Access

Redash is accessible via: **`https://redash.${DOMAIN}`**

Default login credentials:
- **Email:** `admin@example.com`
- **Password:** (set during first-run initialization)

## Starting this App

### From the app folder:
```bash
cd apps/redash
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-redash
```

## Configuration

Before starting Redash for the first time:

1. **Generate a Cookie Secret:**
   ```bash
   openssl rand -hex 32
   ```
   Paste the generated value into `.env` as `REDASH_COOKIE_SECRET`.

2. **Set Database Password:**
   Update `REDASH_DB_PASSWORD` in `.env` to a strong, unique password.

3. **SMTP Configuration:**
   Ensure the following global variables are set in root `.env`:
   - `HOME_CLOUD_SMTP_HOST` - SMTP server hostname
   - `HOME_CLOUD_SMTP_PORT` - SMTP port (typically 587 for TLS)
   - `HOME_CLOUD_SMTP_USERNAME` - SMTP username/email
   - `HOME_CLOUD_SMTP_PASSWORD` - SMTP password
   - `HOME_CLOUD_EMAIL` - Sender email address

4. **First-Run Initialization:**
   After the services start, visit `redash.${DOMAIN}` and complete the setup wizard to create an admin account.

5. **Database Connections:**
   Add data source connections through the Redash UI (Settings → Data Sources). Supported sources include PostgreSQL, MySQL, Elasticsearch, Google BigQuery, and many others.

## Environment Variables

| Variable | Source | Service | Default/Example | Description |
|----------|--------|---------|-----------------|-------------|
| `REDASH_DB_PASSWORD` | Local (.env) | postgres, redash* | (required) | PostgreSQL password for redash user |
| `REDASH_COOKIE_SECRET` | Local (.env) | redash, scheduler, worker | (required) | Secret key for session encryption (use `openssl rand -hex 32`) |
| `REDASH_DATABASE_URL` | docker-compose | redash* | postgresql://redash:...@postgres:5432/redash | PostgreSQL connection string (auto-generated) |
| `REDASH_REDIS_URL` | docker-compose | redash, scheduler, worker | redis://redis:6379/0 | Redis connection string (auto-generated) |
| `REDASH_HOST` | docker-compose | redash | https://redash.${DOMAIN} | Public URL for Redash (used in emails) |
| `REDASH_WEB_WORKERS` | docker-compose | redash | 4 | Number of Gunicorn worker processes |
| `REDASH_LOG_LEVEL` | docker-compose | redash, scheduler, worker | INFO | Logging verbosity (DEBUG, INFO, WARNING, ERROR) |
| `REDASH_ENFORCE_CSRF` | docker-compose | redash | true | Enable CSRF protection for forms |
| `REDASH_MAIL_SERVER` | Global (.env) | redash | ${HOME_CLOUD_SMTP_HOST} | SMTP server hostname |
| `REDASH_MAIL_PORT` | Global (.env) | redash | ${HOME_CLOUD_SMTP_PORT} | SMTP port |
| `REDASH_MAIL_USE_TLS` | docker-compose | redash | true | Use TLS for SMTP connection |
| `REDASH_MAIL_USERNAME` | Global (.env) | redash | ${HOME_CLOUD_SMTP_USERNAME} | SMTP username |
| `REDASH_MAIL_PASSWORD` | Global (.env) | redash | ${HOME_CLOUD_SMTP_PASSWORD} | SMTP password |
| `REDASH_MAIL_DEFAULT_SENDER` | Global (.env) | redash | ${HOME_CLOUD_EMAIL} | Sender email address |
| `TZ` | Global (.env) | postgres, redash, scheduler, worker | (inherited) | Timezone for containers |
| `DOMAIN` | Global (.env) | redash | (inherited) | Domain for Traefik routing |

## Volumes & Networks

| Resource | Type | Purpose |
|----------|------|---------|
| `home_redash_data` | Volume | Redash application data and cache |
| `home_redash_postgres_data` | Volume | PostgreSQL database files |
| `home_redash_redis_data` | Volume | Redis persistent storage |
| `home_network` | Network | External bridge for Traefik routing |
| `home_redash_network` | Network | Internal bridge for service-to-service communication |

## Official Documentation

- **Redash Setup Guide:** https://redash.io/help/open-source/setup
- **Admin Guide:** https://redash.io/help/open-source/admin-guide/
- **Environment Variables:** https://redash.io/help/open-source/admin-guide/env-vars-settings/
- **Docker Setup:** https://github.com/getredash/redash
