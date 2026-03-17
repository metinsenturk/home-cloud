# PostgreSQL

PostgreSQL is a powerful, open-source object-relational database system. This infrastructure service provides a shared PostgreSQL instance that other applications can use for persistent data storage.

## Services

- **infra-postgres**: PostgreSQL 17.x database server

## Access

PostgreSQL is accessible internally via the service name `infra-postgres` on port `5432` within the `home_network`.

**External Access:** Port `5432` is also exposed on the host machine for database management tools like pgAdmin, DBeaver, or TablePlus.

**Connection String Example:**
```
Host: localhost (from host) or infra-postgres (from containers)
Port: 5432
Database: postgres
Username: postgres
Password: <as defined in .env>
```

## Starting this App

### From the app folder:
```bash
cd apps/postgres
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-postgres
```

## Configuration

1. **Set Database Credentials**: Copy `.env.example` to `.env` and set a strong password:
   ```bash
   cp .env.example .env
   # Edit .env and set POSTGRES_PASSWORD
   ```

2. **Default Database**: The `POSTGRES_DB` variable defines the default database created on first startup. Default is `postgres`.

3. **First Run**: On first startup, PostgreSQL will initialize the database cluster. This may take a few seconds.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|----------------------|-------------|
| `POSTGRES_USER` | Local | infra-postgres | `postgres` | PostgreSQL superuser username |
| `POSTGRES_PASSWORD` | Local | infra-postgres | `your_secure_password_here` | PostgreSQL superuser password (required) |
| `POSTGRES_DB` | Local | infra-postgres | `postgres` | Default database to create on initialization |
| `TZ` | Global | infra-postgres | (from root `.env`) | Timezone for the container |

## Volumes & Networks

**Volumes:**
- `home_infra_postgres_data`: Persistent storage for PostgreSQL data directory at `/var/lib/postgresql/data`

**Networks:**
- `home_network`: External network for cross-app communication and Traefik integration

## Using PostgreSQL in Other Apps

When connecting from other containers in your Mini-Cloud, use the following connection settings:

```yaml
environment:
  - DATABASE_HOST=infra-postgres
  - DATABASE_PORT=5432
  - DATABASE_NAME=myapp_db
  - DATABASE_USER=postgres
  - DATABASE_PASSWORD=${POSTGRES_PASSWORD}
```

Make sure the application container is also connected to the `home_network`.

## Creating Application Databases

You can create dedicated databases for each application:

```bash
# Access PostgreSQL shell
docker exec -it infra_postgres psql -U postgres

# Create a new database and user
CREATE DATABASE myapp_db;
CREATE USER myapp_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp_user;
```

Or use database management tools via the exposed port 5432.

## Official Documentation

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [Docker Hub - postgres](https://hub.docker.com/_/postgres)
- [PostgreSQL Docker GitHub](https://github.com/docker-library/postgres)
