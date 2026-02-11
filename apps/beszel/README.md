# Beszel - Server Monitoring

Beszel is a lightweight monitoring hub with historical metrics, alerts, and Docker stats.

## Services

- **beszel**: Web UI and hub backend (port 8090 via Traefik)

## Access

- Web UI: http://beszel.localhost (via Traefik)

## Starting this App

Start from the app folder:

> cd apps/beszel
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-beszel

## Configuration

- `BESZEL_SUBDOMAIN`: Subdomain for the hub (defaults to `beszel`).
- `APP_URL`: Derived in the compose file as `http://<subdomain>.<DOMAIN>`.

## Agents

Beszel requires an agent on each host you want to monitor. The hub UI provides a
ready-to-copy Docker compose snippet when adding a system. If you want to run a
local agent manually, see the official agent installation guide:

https://beszel.dev/guide/agent-installation

## Volumes

- `home_beszel_data`: Persistent hub data storage

## Official Documentation

https://beszel.dev/guide/getting-started
