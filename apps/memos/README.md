# Memos

A privacy-first, lightweight, self-hosted note-taking service. Easily capture and share your great thoughts with full Markdown support.

## Services

| Service | Description |
|---------|-------------|
| `memos` | Main Memos application with embedded SQLite database |

## Access

- **Web UI**: `http://memos.${DOMAIN}` (via Traefik)
- **First-Time Setup**: Create an admin account on first visit
- **Default Port**: 5230 (internal, routed via Traefik)

## Starting this App

### From the app folder
```bash
cd apps/memos
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder
```bash
make up-memos
```

## Configuration

### Initial Setup
1. Start the service using one of the methods above
2. Access the web UI at `http://memos.${DOMAIN}`
3. Create your admin account on first visit
4. Start creating memos!

### Data Storage
- All data is stored in the `home_memos_data` volume
- Includes SQLite database, attachments, and configuration
- Persistent across container restarts

### No Additional Configuration Required
Memos works out of the box with sensible defaults. No environment variables need to be set in the local `.env` file.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `TZ` | Global | `memos` | `UTC` | Timezone for the application |
| `DOMAIN` | Global | `memos` | `localhost` | Domain for Traefik routing |

## Volumes & Networks

### Volumes
- `home_memos_data`: Persistent storage for SQLite database, attachments, and configuration files

### Networks
- `home_network`: External network for Traefik routing and service discovery

## Features

- **Privacy-First**: Self-hosted with zero telemetry and no tracking
- **Markdown Native**: Full markdown support with plain text storage
- **Lightweight**: Single Go binary with minimal resource usage
- **Easy to Deploy**: One-container setup with embedded SQLite
- **Developer-Friendly**: REST and gRPC APIs for integrations
- **Clean Interface**: Minimal design with dark mode support

## Official Documentation

- **Website**: https://usememos.com/
- **Documentation**: https://usememos.com/docs
- **GitHub**: https://github.com/usememos/memos
- **Live Demo**: https://demo.usememos.com/
- **Docker Hub**: https://hub.docker.com/r/neosmemo/memos
