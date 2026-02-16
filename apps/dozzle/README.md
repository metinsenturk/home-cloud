# Dozzle

Dozzle is a lightweight log viewer for Docker containers. It provides a simple, real-time web UI for viewing logs from all containers in your Docker environment without requiring shell access.

## Services

- **dozzle** – A web service that aggregates and displays Docker container logs in real-time.

## Access

- **Log Viewer:** `http://logs.${DOMAIN}` (routed through Traefik)

## Starting this App

From the app folder:
```bash
cd apps/dozzle
docker compose --env-file ../../.env -f docker-compose.yml up -d
```

From the root folder:
```bash
make up-dozzle
```

## Configuration

- **Docker Socket Access:** Dozzle requires read-only access to the Docker socket to list and read logs from containers.
- **Traefik Routing:** Automatically routed to `logs.${DOMAIN}` via Traefik labels.
- **No Authentication:** Dozzle runs with open access (consider restricting at the firewall level).

### Key Environment Variables

- `${DOMAIN}` – Used in Traefik routing rule (inherited from root `.env`)
- `${TZ}` – Timezone for log timestamps (inherited from root `.env`)

## Volumes & Networks

- **Docker Socket:** Bind-mounted RO (`/var/run/docker.sock`) for reading container logs
- **Networks:** Connected to `home_network` for Traefik routing

## Official Documentation

- [Dozzle GitHub](https://github.com/amir20/dozzle)
- [Dozzle Docker Hub](https://hub.docker.com/r/amir20/dozzle)
