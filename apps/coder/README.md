# Coder - Self-Hosted Cloud Development Environments

Coder lets you run secure, self-hosted development environments and manage workspaces from a browser UI.

## Services

- **coder**: Web UI and API service (port 3000 via Traefik)
- **coder-db**: PostgreSQL database for Coder metadata and state

## Access

- Web UI: http://coder.${DOMAIN}

## Starting this App

Start from the app folder:

> cd apps/coder
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-coder

## Configuration

- `CODER_ACCESS_URL`: External URL that users and workspaces use to reach Coder.
- `CODER_WILDCARD_ACCESS_URL`: Wildcard URL used for workspace apps and port forwarding.
- `CODER_HTTP_ADDRESS`: Bind address for the HTTP listener (set to 0.0.0.0:3000).
- `CODER_PG_CONNECTION_URL`: PostgreSQL connection string for Coder.
- If you plan to use Docker-based templates, ensure the container can access `/var/run/docker.sock`.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| CODER_ACCESS_URL | Local | coder | https://coder.${DOMAIN} | External URL used to access Coder. |
| CODER_WILDCARD_ACCESS_URL | Local | coder | *.coder.${DOMAIN} | Wildcard URL for workspace apps. |
| CODER_HTTP_ADDRESS | Local | coder | 0.0.0.0:3000 | HTTP bind address for Coder. |
| CODER_PG_CONNECTION_URL | Local | coder | postgresql://coder:your_password_here@coder-db:5432/coder?sslmode=disable | PostgreSQL connection string. |
| CODER_DB_USER | Local | coder-db | coder | PostgreSQL user for Coder. |
| CODER_DB_PASSWORD | Local | coder-db | your_password_here | PostgreSQL password for Coder. |
| CODER_DB_NAME | Local | coder-db | coder | PostgreSQL database name. |

## Volumes & Networks

- **home_coder_db_data**: Persistent storage for PostgreSQL data.
- **home_coder_home_data**: Persistent storage for Coder home directory.
- **home_coder_network**: Internal bridge network for Coder and PostgreSQL.
- **home_network**: External network for Traefik routing.

## Official Documentation

https://coder.com/docs
