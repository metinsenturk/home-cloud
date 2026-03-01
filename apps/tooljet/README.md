# ToolJet

ToolJet is an open-source low-code framework to build and deploy internal tools, dashboards, and business applications with minimal engineering effort. It features a drag-and-drop visual app builder, 80+ data source integrations, and built-in database functionality.

## Services

| Service | Description |
|---------|-------------|
| **tooljet** | Main ToolJet application server (Node.js). Handles app building, user authentication, and application logic with built-in Redis for workflow scheduling. |
| **tooljet-db** | Dedicated PostgreSQL 16 (Alpine) database service for ToolJet's data storage. Isolated to this application stack. |
| **tooljet-redis** | Dedicated Redis service for job queue coordination between ToolJet server and worker processes. |
| **tooljet-worker** | Dedicated ToolJet worker container (`WORKER=true`) for workflow scheduling and background job execution. |
| **postgrest** | PostgREST v12.2.0 API server providing automatic RESTful API access to the PostgreSQL database. Useful for JavaScript queries and custom integrations. |

## Access

- **ToolJet URL:** `http://tooljet.${DOMAIN}` (via Traefik)
- **PostgREST API URL:** `http://tooljet-api.${DOMAIN}` (via Traefik)
- **Default Port (Local):** 3000 for ToolJet, 3000 for PostgREST (both accessed through Traefik, not directly exposed to host)
- **Admin Setup:** On first access, you'll be prompted to create the initial admin user

## Starting this App

### From the app folder:
```bash
cd apps/tooljet
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-tooljet
```

### Stopping the app:
```bash
make down-tooljet
```

## Configuration

### Prerequisites
- Ensure Traefik is running and the `home_network` exists
- Root `.env` file must have `TZ` and `DOMAIN` variables defined
- No external database required - PostgreSQL runs as part of this compose stack
- No external Redis required - Redis runs as part of this compose stack

### Initial Setup Steps
1. Access `http://tooljet.${DOMAIN}` in your browser
2. Create the initial admin user with your preferred email and password
3. Log in to the workspace
4. Optional: Configure SMTP for email notifications
5. Optional: Configure external data sources and integrations

### Database Initialization
ToolJet automatically creates the required databases (`tooljet` and `tooljet_db`) on the dedicated `tooljet-db` PostgreSQL service on first startup. The database runs in an isolated container with persistent storage in the `home_tooljet_postgres_data` volume.

### Workflows and Worker Mode
This stack includes a dedicated `tooljet-worker` service for workflow scheduling. As recommended by ToolJet docs for separate worker containers, an external stateful Redis service (`tooljet-redis`) is included for queue coordination.

### Important Security Notes
- **Generate New Keys for Production:** The security keys in `.env` (LOCKBOX_MASTER_KEY, SECRET_KEY_BASE, PGRST_JWT_SECRET) must be regenerated for production environments using the commands in `.env.example`
- **Database Password:** Change `TOOLJET_PG_PASS` in `.env` to a strong password before deploying to production
- **HTTPS:** For production, ensure `TOOLJET_HOST` uses `https://` instead of `http://`

## Environment Variables

| Variable | Source | Service | Default/Example | Description |
|----------|--------|---------|-----------------|-------------|
| `TOOLJET_PG_HOST` | Local | tooljet, postgrest | `tooljet-db` | PostgreSQL service name in the compose stack |
| `TOOLJET_PG_DB` | Local | tooljet, postgrest, tooljet-db | `tooljet` | Main application database name |
| `TOOLJET_PG_USER` | Local | tooljet, postgrest, tooljet-db | `tooljet` | PostgreSQL user for ToolJet |
| `TOOLJET_PG_PASS` | Local | tooljet, postgrest, tooljet-db | (working default) | PostgreSQL password - **change in production** |
| `TOOLJET_REDIS_HOST` | Local | tooljet, tooljet-worker | `tooljet-redis` | Redis service name for job queue coordination |
| `TOOLJET_REDIS_PORT` | Local | tooljet, tooljet-worker | `6379` | Redis port |
| `TOOLJET_WORKFLOW_CONCURRENCY` | Local | tooljet-worker | `5` | Number of workflow jobs processed concurrently by worker |
| `TOOLJET_DB_NAME` | Local | tooljet | `tooljet_db` | Internal ToolJet database name for the ToolJet Database feature |
| `TOOLJET_LOCKBOX_KEY` | Local | tooljet | (32-byte hex) | Encryption key for datasource credentials (AES-256-GCM). Generated via `openssl rand -hex 32` |
| `TOOLJET_SECRET_KEY` | Local | tooljet | (64-byte hex) | Session encryption key. Generated via `openssl rand -hex 64` |
| `TOOLJET_PGRST_JWT_SECRET` | Local | tooljet, postgrest | (32-byte hex) | JWT secret for PostgREST authentication. Generated via `openssl rand -hex 32` |
| `DOMAIN` | Global | tooljet, postgrest | (from root .env) | Used to construct Traefik routing rules for both services |
| `TZ` | Global | tooljet, postgrest, tooljet-db, tooljet-redis, tooljet-worker | (from root .env) | Container timezone |

**Source Values:**
- **Local:** Defined in `.env` file within the tooljet app folder
- **Global:** Inherited from root `.env` via the Makefile's double-environment pattern

## Volumes & Networks

### Volumes

| Volume | Mount Point | Purpose |
|--------|------------|---------|
| `home_tooljet_data` | `/var/lib/postgresql/13/main` | Persistent storage for ToolJet's embedded metadata (reserved for compatibility) |
| `home_tooljet_postgres_data` | `/var/lib/postgresql/data` | PostgreSQL database files for ToolJet's dedicated database service |
| `home_tooljet_redis_data` | `/data` | Redis append-only data for queue durability |
### Networks

| Network | Type | Purpose |
|---------|------|---------|
| `home_network` | External | Traefik reverse proxy network - enables `tooljet.${DOMAIN}` and `tooljet-api.${DOMAIN}` routing; also used for inter-service communication between tooljet, tooljet-db, and postgrest |

### Service Dependencies

- **tooljet** depends on **tooljet-db** being healthy before starting
- **tooljet-worker** depends on **tooljet-db** and **tooljet-redis** being healthy before starting
- **postgrest** depends on **tooljet-db** being healthy before starting
- All services communicate on the `home_network`

## Official Documentation

- **Main Documentation:** https://docs.tooljet.com/
- **Docker Deployment Guide:** https://docs.tooljet.com/docs/setup/docker
- **Environment Variables Reference:** https://docs.tooljet.com/docs/setup/env-vars
- **GitHub Repository:** https://github.com/ToolJet/ToolJet
- **Community Slack:** https://tooljet.com/slack
