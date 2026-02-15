# Mage.ai

A modern data pipeline tool for building, running, and managing data workflows. Mage provides a hybrid framework for transforming and integrating data, with support for Python, SQL, and R.

## Services

- **mage**: The main Mage.ai application server for building and orchestrating data pipelines
- **mage-db**: PostgreSQL database for storing Mage.ai metadata, pipeline configurations, and execution history

## Access

- **Web UI**: `http://mage.${DOMAIN}`
  - Default access with no authentication required (can be configured)

## Starting this App

### From the app folder:
```bash
cd apps/mage
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-mage
```

## Configuration

1. **Environment Variables**: Copy `.env.example` to `.env` and customize if needed
2. **Database Credentials**: Update `MAGE_DB_PASSWORD` in `.env` with a secure password
3. **Project Name**: The `PROJECT_NAME` variable defines the workspace/project name (default: `default_repo`)
4. **Network Binding**: The `HOST` variable must be set to `0.0.0.0` to allow Traefik to proxy requests
5. **First Launch**: On first startup, Mage.ai will initialize the database schema and project structure

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `PROJECT_NAME` | Local | mage | `default_repo` | Name of the Mage.ai project/workspace |
| `HOST` | Local | mage | `0.0.0.0` | Network interface to bind to (required for container access) |
| `PORT` | Local | mage | `6789` | Internal web server port |
| `DEFAULT_OWNER_EMAIL` | Local | mage | Admin email address |
| `DEFAULT_OWNER_PASSWORD` | Local | mage | Admin password |
| `DEFAULT_OWNER_USERNAME` | Local | mage | Admin username |
| `MAGE_DB_USER` | Local | mage-db, mage | `mage` | PostgreSQL database username |
| `MAGE_DB_PASSWORD` | Local | mage-db, mage | `change_this_secure_password` | PostgreSQL database password (change in production) |
| `MAGE_DB_NAME` | Local | mage-db, mage | `mage` | PostgreSQL database name |
| `TZ` | Global | mage, mage-db | `UTC` | Timezone for the containers |
| `DOMAIN` | Global | mage | `localhost` | Base domain for Traefik routing |

## Volumes & Networks

### Volumes
- **home_mage_data**: Persistent storage for Mage.ai projects, pipelines, and configurations
- **home_mage_db_data**: PostgreSQL database storage for metadata and execution history

### Networks
- **home_network**: External network for Traefik routing and cross-app communication
- **home_mage_network**: Internal network for secure communication between Mage app and PostgreSQL database

## Features

- **Interactive Pipeline Builder**: Visual interface for building data pipelines
- **Multi-Language Support**: Write transformations in Python, SQL, or R
- **Scheduling**: Built-in scheduler for running pipelines on a schedule
- **Data Integration**: Connect to various data sources (databases, APIs, cloud storage)
- **Version Control**: Git integration for tracking pipeline changes
- **Observability**: Monitor pipeline execution with logs and metrics
- **PostgreSQL Backend**: Uses PostgreSQL for robust metadata storage and improved performance over SQLite

## Official Documentation

- [Mage.ai Official Docs](https://docs.mage.ai/)
- [Docker Hub Image](https://hub.docker.com/r/mageai/mageai)
- [GitHub Repository](https://github.com/mage-ai/mage-ai)
