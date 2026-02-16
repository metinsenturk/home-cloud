# WUD (What's Up Docker)

What's Up Docker (WUD) is a Docker image update checker. It monitors your running containers and their images for available updates, providing a web UI to view update status and manage the update process.

## Services

- **wud** – A web service that watches Docker containers for image updates and displays available upgrades.

## Access

- **Update Dashboard:** `http://updates.${DOMAIN}` (routed through Traefik)

## Starting this App

From the app folder:
```bash
cd apps/wud
docker compose --env-file ../../.env -f docker-compose.yml up -d
```

From the root folder:
```bash
make up-wud
```

## Configuration

- **Docker Socket Access:** WUD requires read-only access to the Docker socket to list containers and check image registries.
- **Traefik Routing:** Automatically routed to `updates.${DOMAIN}` via Traefik labels.
- **Registry Checking:** WUD periodically checks Docker registries (Docker Hub, GHCR, Quay, etc.) for newer versions of running images.

### Key Environment Variables

- `${DOMAIN}` – Used in Traefik routing rule (inherited from root `.env`)
- `${TZ}` – Timezone for update check logs (inherited from root `.env`)

## Volumes & Networks

- **Docker Socket:** Bind-mounted RO (`/var/run/docker.sock`) for container monitoring
- **Networks:** Connected to `home_network` for Traefik routing

## Official Documentation

- [WUD GitHub](https://github.com/getwud/wud)
- [WUD Docker Hub](https://hub.docker.com/r/getwud/wud)
