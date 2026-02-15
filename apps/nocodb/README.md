# NocoDB

NocoDB is a free and self-hostable Airtable alternative that provides an intuitive spreadsheet interface for managing databases. It enables users to build and collaborate on databases with the ease and familiarity of a spreadsheet, without requiring coding knowledge.

## Services

| Service | Description |
|---------|-------------|
| **nocodb** | Web UI and REST API for NocoDB, providing a spreadsheet-like interface for database management |
| **nocodb-db** | PostgreSQL database service storing NocoDB's internal metadata, users, and configurations |

## Access

NocoDB is accessible via your web browser at:

```
https://nocodb.${DOMAIN}
```

Log in with the admin credentials defined in your `.env` file (mapped from global `HOME_CLOUD_EMAIL` and `HOME_CLOUD_PASSWORD`).

## Starting this App

### From the app folder:
```bash
cd apps/nocodb
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-nocodb
```

## Configuration

### Environment Variables

Before starting NocoDB, ensure the following are configured in `apps/nocodb/.env`:

1. **NC_ADMIN_EMAIL** and **NC_ADMIN_PASSWORD** — Inherited from global `.env` (HOME_CLOUD_EMAIL and HOME_CLOUD_PASSWORD)
   - These credentials are used for the initial admin account
   - Can be changed later via the NocoDB UI

2. **NC_AUTH_JWT_SECRET** — A unique random secret used for JWT token signing
   - Generate a secure random secret: `openssl rand -hex 32`
   - **Important:** Keep this secret consistent; changing it will invalidate all existing tokens

3. **POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB** — PostgreSQL credentials for NocoDB's internal database
   - These define the database user, password, and database name
   - Must be set before first launch

### Initial Setup

After starting NocoDB for the first time:
1. Access the UI at `nocodb.${DOMAIN}`
2. Log in with the admin credentials (HOME_CLOUD_EMAIL and HOME_CLOUD_PASSWORD)
3. Configure your databases:
   - Create new bases/tables in NocoDB
   - Optionally connect to external databases (e.g., infra-postgres) for data reflection and visualization

### Database Connection

NocoDB is configured to use its own PostgreSQL instance (`nocodb-db`) for internal metadata. Users can optionally connect NocoDB to external databases (including `infra-postgres`) via the NocoDB UI to reflect and work with existing data.

## Environment Variables

| Variable | Source | Service | Default | Description |
|----------|--------|---------|---------|-------------|
| `NC_ADMIN_EMAIL` | Global | nocodb | `${HOME_CLOUD_EMAIL}` | Admin account email address |
| `NC_ADMIN_PASSWORD` | Global | nocodb | `${HOME_CLOUD_PASSWORD}` | Admin account password (must be at least 8 characters with uppercase, number, and special character) |
| `NC_AUTH_JWT_SECRET` | Local | nocodb | (required) | JWT secret for token signing; must be unique and complex |
| `POSTGRES_USER` | Local | nocodb-db | `nocodb` | PostgreSQL username for NocoDB's database |
| `POSTGRES_PASSWORD` | Local | nocodb-db | (required) | PostgreSQL password for NocoDB's database |
| `POSTGRES_DB` | Local | nocodb-db | `nocodb` | PostgreSQL database name for NocoDB's metadata |
| `TZ` | Global | nocodb-db | (inherited) | Timezone setting (inherited from root `.env`) |

## Volumes & Networks

| Name | Type | Purpose |
|------|------|---------|
| `home_nocodb_data` | Volume | Stores NocoDB application data and files |
| `home_nocodb_db_data` | Volume | Stores PostgreSQL data for NocoDB's metadata database |
| `home_network` | Network (external) | Shared network for all services; enables Traefik routing and service discovery |
| `home_nocodb_network` | Network (internal) | Private bridge network for internal communication between `nocodb` and `nocodb-db` |

## Official Documentation

For more information about NocoDB, visit:
- **Main Documentation:** https://nocodb.com/docs/
- **Self-hosting Guide:** https://nocodb.com/docs/self-hosting/
- **Environment Variables:** https://nocodb.com/docs/self-hosting/environment-variables
- **GitHub Repository:** https://github.com/nocodb/nocodb
