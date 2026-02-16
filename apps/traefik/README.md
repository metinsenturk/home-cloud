# Traefik

Traefik is a modern, dynamic reverse proxy and load balancer built for containerized environments. It automatically discovers services via Docker labels and routes traffic based on hostnames.

## Services

- **traefik** – The reverse proxy service that routes HTTPS traffic to containers based on hostname labels (e.g., `app.${DOMAIN}`).

## Access

- **Dashboard:** `http://traefik.${DOMAIN}` (internally routed via Traefik itself)
- **HTTP/HTTPS:** Listens on ports 80 and 443 for all incoming web traffic

## Starting this App

From the app folder:
```bash
cd apps/traefik
docker compose --env-file ../../.env -f docker-compose.yml up -d
```

From the root folder:
```bash
make up-traefik
```

## Configuration

- **Service Discovery:** Traefik monitors the Docker socket to automatically detect new containers with `traefik.enable=true` labels.
- **Default Expose:** All containers must explicitly opt-in with `traefik.enable=true` (default is disabled).
- **Entrypoints:** HTTP on port 80, HTTPS on port 443.
- **Logging:** All requests are logged at INFO level.

### Key Environment Variables

Traefik inherits global configuration:
- `${DOMAIN}` – The base domain for routing rules (e.g., `app.${DOMAIN}`)
- `${TZ}` – Timezone for logs and timestamps

## Volumes & Networks

- **Docker Socket:** Bind-mounted RO (`/var/run/docker.sock`) for service discovery
- **Networks:** Connected to `home_network` for DNS resolution and routing

## Official Documentation

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Routing & Middleware](https://doc.traefik.io/traefik/routing/overview/)
