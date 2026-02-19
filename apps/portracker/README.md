# Portracker

Portracker is a self-hosted, real-time port monitoring and discovery dashboard.

## Services

- **portracker**: Web UI and port discovery service (SQLite embedded)

## Access

- Web UI: http://portracker.${DOMAIN}

## Starting this App

Start from the app folder:

> cd apps/portracker
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-portracker

## Configuration

- The container needs access to the Docker socket for container discovery.
- `pid: "host"` and the extra capabilities allow host port detection.
- Enable auth by setting `ENABLE_AUTH=true` and a `SESSION_SECRET` in the local `.env`.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `PORT` | Local | portracker | `4999` | Port the web server listens on inside the container. |
| `DATABASE_PATH` | Local | portracker | `/data/portracker.db` | Path to the embedded SQLite database. |
| `ENABLE_AUTH` | Local | portracker | `false` | Enable login protection for the dashboard. |
| `SESSION_SECRET` | Local | portracker | `your-session-secret-here` | Session signing secret when auth is enabled. |
| `TRUENAS_API_KEY` | Local | portracker | `your-truenas-api-key-here` | Optional key for enhanced TrueNAS discovery. |
| `DEBUG` | Local | portracker | `false` | Enable verbose logging for troubleshooting. |
| `DOMAIN` | Global | portracker | `localhost` | Base domain used for Traefik host rules. |
| `TZ` | Global | portracker | `UTC` | Time zone for container logs and timestamps. |

## Volumes & Networks

- **Bind Mounts**:
  - `/var/run/docker.sock:/var/run/docker.sock:ro` (container discovery)
- **Volumes**:
  - `home_portracker_data`: SQLite data storage
- **Networks**:
  - `home_network`: External network for Traefik routing

## Official Documentation

https://github.com/mostafa-wahied/portracker
