# Apache Superset

Apache Superset is a modern, enterprise-ready business intelligence web application. It is fast, lightweight, intuitive, and loaded with options that make it easy for users to explore and visualize data.

## Services

This deployment includes multiple services:

- **superset** - The main Superset web application server
- **superset-postgres** - PostgreSQL database for storing Superset metadata (dashboards, users, queries)
- **superset-redis** - Redis cache and message broker for Celery
- **superset-worker** - Celery worker for asynchronous task processing (alerts, reports, long-running queries)
- **superset-worker-beat** - Celery beat scheduler for periodic tasks

## Access

Once running, Superset is accessible at:

**URL:** `http://superset.${DOMAIN}` (e.g., `http://superset.localhost`)

**Default Admin Credentials:**
- **Username:** `admin`
- **Password:** Must be set during initialization (see Configuration section)

## Starting this App

### From the app folder:
```bash
cd apps/superset
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-superset
```

## Configuration

### 1. Environment Variables

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` and set:
- **DATABASE_PASSWORD** - Strong password for PostgreSQL
- **SUPERSET_SECRET_KEY** - Generate with: `python3 -c "import secrets; print(secrets.token_urlsafe(42))"`
- **SUPERSET_LOAD_EXAMPLES** - Set to `yes` to load sample dashboards (optional)

### 2. Initialize Superset

After starting the services for the first time, you need to initialize the database and create an admin user:

```bash
# Run database migrations
docker exec -it superset superset db upgrade

# Create admin user (follow prompts to set username/password)
docker exec -it superset superset fab create-admin

# Initialize Superset (creates default roles and permissions)
docker exec -it superset superset init

# (Optional) Load example data
docker exec -it superset superset load_examples
```

**Note:** These initialization steps are required only on first deployment.

### 3. Connecting Databases

Superset can connect to various databases for visualization:

1. Log in to Superset web interface
2. Navigate to **Settings** → **Database Connections**
3. Click **+ Database** to add a new connection
4. Select your database type and enter connection details

**Example: Connecting to infra-postgres**
- **Supported Databases:** (e.g., `postgresql+psycopg2://user:password@infra-postgres:5432/dbname`)
- **SQLAlchemy URI Format:** `postgresql+psycopg2://user:password@host:port/database`

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `DOMAIN` | Global | superset | `localhost` | Domain for Traefik routing |
| `DATABASE_DIALECT` | Local | superset, worker, worker-beat | `postgresql` | Database type (fixed) |
| `DATABASE_USER` | Local | superset, worker, worker-beat, postgres | `superset` | PostgreSQL username |
| `DATABASE_PASSWORD` | Local | superset, worker, worker-beat, postgres | - | PostgreSQL password (required) |
| `DATABASE_HOST` | Local | superset, worker, worker-beat | `superset-postgres` | PostgreSQL container name |
| `DATABASE_PORT` | Local | superset, worker, worker-beat | `5432` | PostgreSQL port |
| `DATABASE_DB` | Local | superset, worker, worker-beat, postgres | `superset` | PostgreSQL database name |
| `REDIS_HOST` | Local | superset, worker, worker-beat | `superset-redis` | Redis container name |
| `REDIS_PORT` | Local | superset, worker, worker-beat | `6379` | Redis port |
| `SUPERSET_SECRET_KEY` | Local | superset, worker, worker-beat | - | Flask secret key (required, generate securely) |
| `SUPERSET_LOAD_EXAMPLES` | Local | superset | `no` | Load sample dashboards on init |

## Volumes & Networks

### Volumes

- **home_superset_data** - Superset application data (shared across main app and workers)
- **home_superset_postgres_data** - PostgreSQL data persistence
- **home_superset_redis_data** - Redis data persistence

### Networks

- **home_network** - External bridge network for Traefik routing (public access)
- **home_superset_network** - Internal bridge network for service-to-service communication (postgres, redis, workers)

## Troubleshooting

### Database Not Initialized
If you see errors about missing tables, run the initialization commands:
```bash
docker exec -it superset superset db upgrade
docker exec -it superset superset init
```

### Worker/Beat Not Processing Tasks
Check worker logs:
```bash
docker logs superset_worker
docker logs superset_worker_beat
```

Common issues:
- Ensure Redis is healthy: `docker exec -it superset_redis redis-cli ping`
- Verify SECRET_KEY is identical across all services

### Can't Access Web UI
1. Check Traefik is running: `docker ps | grep traefik`
2. Verify service is healthy: `docker ps | grep superset`
3. Check logs: `docker logs superset`
4. Ensure DNS resolution: `http://superset.localhost` should resolve

## Official Documentation

- **Superset Documentation:** https://superset.apache.org/docs/intro
- **Installation Guide:** https://superset.apache.org/docs/installation/docker-compose
- **Configuration:** https://superset.apache.org/docs/configuration/configuring-superset
- **Docker Hub:** https://hub.docker.com/r/apache/superset
- **GitHub Repository:** https://github.com/apache/superset
