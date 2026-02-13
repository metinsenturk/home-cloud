# marimo

A reactive Python notebook environment with native SQL support. marimo is a modern, Git-friendly alternative to Jupyter that automatically manages cell dependencies and keeps your code and outputs consistent.

## Services

- **marimo**: The main marimo editor service running on port 8080 with SQL support pre-installed.

## Access

- **URL**: `http://marimo.${DOMAIN}`
- **Local**: `http://marimo.localhost`

## Starting this App

### From the app folder:
```bash
cd apps/marimo
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-marimo
```

## Configuration

No additional configuration is required. The service starts with:
- `marimo edit` mode (interactive notebook editor)
- `--no-token` flag (disables authentication token requirement)
- Port 8080 (internal) → routed via Traefik as `marimo.${DOMAIN}`
- `--host 0.0.0.0` (listens on all interfaces for Traefik to reach it)

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---|---|---|---|---|
| `TZ` | Global | marimo | `UTC` | Timezone for the container |
| `DOMAIN` | Global | marimo | `localhost` | Domain for Traefik routing |

## Volumes & Networks

| Name | Type | Purpose |
|---|---|---|
| `home_marimo_data` | Volume | Persistent storage for marimo editor configuration and state (`.marimo` directory) |
| `home_network` | Network | External bridge network for Traefik routing |

## Official Documentation

- [marimo Documentation](https://docs.marimo.io/)
- [marimo GitHub](https://github.com/marimo-team/marimo)
- [marimo Docker Deployment Guide](https://docs.marimo.io/guides/deploying/deploying_docker/)
- [marimo Prebuilt Containers](https://docs.marimo.io/guides/deploying/prebuilt_containers/)
