# Glance - Self-Hosted Dashboard

Glance is a lightweight, customizable dashboard for feeds, widgets, and quick status views.

## Services

- **glance**: Web UI (port 8080 via Traefik)

## Access

- Web UI: http://glance.localhost (via Traefik)

## Starting this App

Start from the app folder:

> cd apps/glance
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-glance

## Configuration

- `glance.yml` is bind-mounted to `/app/config/glance.yml` so you can edit the dashboard layout without rebuilding the image.
- `server.proxied: true` is set so Glance respects reverse proxy headers from Traefik.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `GLANCE_SUBDOMAIN` | Local | glance | `glance` | Subdomain for the Glance UI. |
| `GLANCE_PORT` | Local | glance | `8080` | Port used by the Glance server inside the container. |
| `DOMAIN` | Global | glance | `localhost` | Base domain used for Traefik host rules. |
| `TZ` | Global | glance | `UTC` | Time zone for container logs and widgets. |

## Volumes & Networks

- **Bind Mounts**:
  - `./glance.yml:/app/config/glance.yml:ro` (Glance configuration)
  - `./assets:/app/public/assets:ro` (Custom images/icons)
- **Volumes**:
  - `home_glance_data`: Persistent Glance data
- **Networks**:
  - `home_glance_network`: Internal app network
  - `home_network`: External network for Traefik routing

## Official Documentation

https://github.com/glanceapp/glance
