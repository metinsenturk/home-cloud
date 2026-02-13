# pgAdmin 4

pgAdmin 4 is the most popular and feature-rich open-source administration and development platform for PostgreSQL. It provides a web-based interface for managing PostgreSQL databases, executing SQL queries, and administering database objects.

## Services

| Service | Description |
|---------|-------------|
| **pgadmin** | Web-based PostgreSQL administration interface |

## Access

pgAdmin 4 is accessible at:
```
https://pgadmin.<DOMAIN>
```

Default credentials (configured via environment variables):
- **Email**: `admin@localhost` (from `.env`)
- **Password**: `changeme` (from `.env`)

> **⚠️ Important**: Change the default credentials in `.env` file before deploying to production.

## Starting this App

### From the app folder:
```bash
cd apps/pgadmin
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-pgadmin
```

## Configuration

### Required Setup

1. **Set credentials**: Edit `apps/pgadmin/.env` and update:
   - `PGADMIN_DEFAULT_EMAIL`: Administrator email address
   - `PGADMIN_DEFAULT_PASSWORD`: Administrator password

2. **First Login**: After starting the container, log in with the credentials set above.

3. **Add Database Servers** (Optional):
   - Once logged in, add PostgreSQL servers in pgAdmin to manage them
   - Example: If you have a PostgreSQL container named `postgres` on the `home_network`, you can connect to it using the container name as the hostname

### Additional Configuration

pgAdmin can be further customized through PGADMIN_CONFIG_* environment variables. For example:
- `PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True` - Enable enhanced cookie protection
- `PGADMIN_CONFIG_CONSOLE_LOG_LEVEL=10` - Set console logging level

## Environment Variables

| Variable Name | Source | Service | Default/Example | Description |
|---------------|--------|---------|-----------------|-------------|
| `PGADMIN_DEFAULT_EMAIL` | Local (`.env`) | pgadmin | `admin@localhost` | Administrator email for initial login |
| `PGADMIN_DEFAULT_PASSWORD` | Local (`.env`) | pgadmin | `changeme` | Administrator password for initial login |
| `PGADMIN_DISABLE_POSTFIX` | docker-compose.yml | pgadmin | `true` | Disables Postfix email server (not needed in container environment) |
| `PGADMIN_LISTEN_ADDRESS` | docker-compose.yml | pgadmin | `0.0.0.0` | Address pgAdmin listens on (0.0.0.0 required for Traefik routing) |
| `TZ` | Global (root `.env`) | pgadmin | `UTC` | Timezone for the container |
| `DOMAIN` | Global (root `.env`) | pgadmin | N/A | Your domain name (used for Traefik routing) |

## Volumes & Networks

| Name | Type | Mount Point | Description |
|------|------|-------------|-------------|
| `home_network` | Network | External Network | Traefik reverse proxy network for routing |
| `home_pgadmin_data` | Volume | `/var/lib/pgadmin` | Configuration database, session data, and user files |

## Official Documentation

- [pgAdmin 4 Container Deployment Documentation](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html)
- [pgAdmin 4 Getting Started Guide](https://www.pgadmin.org/docs/pgadmin4/latest/getting_started.html)
- [pgAdmin 4 Project Website](https://www.pgadmin.org/)
