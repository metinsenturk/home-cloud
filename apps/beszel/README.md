# Beszel - Server Monitoring

Beszel is a lightweight monitoring hub with historical metrics, alerts, and Docker stats.

## Services

- **beszel**: Web UI and hub backend (port 8090 via Traefik)
- **beszel-agent**: Local agent that sends host and Docker metrics to the hub

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
- `BESZEL_AGENT_LISTEN`: Agent listen port (defaults to `45876`).
- `BESZEL_AGENT_HUB_URL`: Hub URL the agent connects to (defaults to `http://beszel:8090`).
- `BESZEL_AGENT_KEY`: Public key from the hub Add System dialog.
- `BESZEL_AGENT_TOKEN`: Token from the hub (`/settings/tokens`).

## Agents

The local `beszel-agent` service reads Docker stats via the Docker socket and
sends metrics to the hub. Before starting, open the hub and create a system to
retrieve the `KEY` and `TOKEN` values, then update the app `.env` file.

If you want to run agents on other hosts, the hub UI provides ready-to-copy
snippets when adding a system. The full agent guide is here:

https://beszel.dev/guide/agent-installation

## Volumes

- `home_beszel_data`: Persistent hub data storage
- `home_beszel_agent_data`: Persistent agent data storage

## Official Documentation

https://beszel.dev/guide/getting-started
