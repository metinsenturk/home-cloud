# Mage.ai

A modern data pipeline tool for building, running, and managing data workflows. Mage provides a hybrid framework for transforming and integrating data, with support for Python, SQL, and R.

## Services

- **mage**: The main Mage.ai application server for building and orchestrating data pipelines

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
2. **Project Name**: The `PROJECT_NAME` variable defines the workspace/project name (default: `default_repo`)
3. **Network Binding**: The `HOST` variable must be set to `0.0.0.0` to allow Traefik to proxy requests
4. **First Launch**: On first startup, Mage.ai will initialize the project structure in the persistent volume

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `PROJECT_NAME` | Local | mage | `default_repo` | Name of the Mage.ai project/workspace |
| `HOST` | Local | mage | `0.0.0.0` | Network interface to bind to (required for container access) |
| `PORT` | Local | mage | `6789` | Internal web server port |
| `TZ` | Global | mage | `UTC` | Timezone for the container |
| `DOMAIN` | Global | mage | `localhost` | Base domain for Traefik routing |

## Volumes & Networks

### Volumes
- **home_mage_data**: Persistent storage for Mage.ai projects, pipelines, configurations, and SQLite database

### Networks
- **home_network**: External network for Traefik routing and cross-app communication

## Features

- **Interactive Pipeline Builder**: Visual interface for building data pipelines
- **Multi-Language Support**: Write transformations in Python, SQL, or R
- **Scheduling**: Built-in scheduler for running pipelines on a schedule
- **Data Integration**: Connect to various data sources (databases, APIs, cloud storage)
- **Version Control**: Git integration for tracking pipeline changes
- **Observability**: Monitor pipeline execution with logs and metrics

## Official Documentation

- [Mage.ai Official Docs](https://docs.mage.ai/)
- [Docker Hub Image](https://hub.docker.com/r/mageai/mageai)
- [GitHub Repository](https://github.com/mage-ai/mage-ai)
