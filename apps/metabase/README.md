# Metabase - Data Analytics & Visualization

Metabase is an open-source business intelligence and analytics platform. It provides intuitive dashboards, charts, and insights from connected data sources.

## Services

- **metabase**: Web UI and analytics backend (port 3000 via Traefik)
- **metabase-db**: PostgreSQL database for Metabase metadata storage

## Access

- Web UI: http://metabase.localhost (via Traefik)

## Starting this App

Start from the app folder:

> cd apps/metabase
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-metabase

## Configuration

- `METABASE_SUBDOMAIN`: Subdomain for Metabase (defaults to `metabase`).
- `METABASE_DB_USER`: PostgreSQL user for Metabase (defaults to `metabase`).
- `METABASE_DB_PASSWORD`: PostgreSQL password for Metabase database.
- `METABASE_DB_NAME`: PostgreSQL database name (defaults to `metabase`).

## First-Time Setup

1. Start the service: `make up-metabase`
2. Visit http://metabase.localhost
3. Complete the setup wizard
4. Create your admin account
5. Connect data sources and start creating dashboards

## Network Architecture

- **home_metabase_network**: Internal network for communication between Metabase and PostgreSQL
- **home_network**: External network for Traefik routing (only the main Metabase service connects here)

## Volumes

- `home_metabase_db_data`: PostgreSQL data storage

## Official Documentation

https://www.metabase.com/docs/latest/
