# Dockhand

A modern, lightweight Docker management UI built for homelabs. Dockhand provides an intuitive interface for container operations, compose stack deployment, observability, and security management. It's a Portainer alternative with zero telemetry and minimal dependencies.

## Services

- **dockhand**: The main Docker management UI (port 3000 internally). Provides a web-based interface for managing containers, images, volumes, networks, and Docker Compose stacks.

## Access

Access Dockhand at: `http://dockhand.${DOMAIN}` (e.g., `http://dockhand.localhost`)

The UI is exposed through Traefik reverse proxy.

## Starting this App

### From the app folder:

```bash
cd apps/dockhand
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:

```bash
make up-dockhand
```

To stop the service:

```bash
make down-dockhand
```

## Configuration

### Initial Setup

Dockhand requires no initial configuration. On first access:

1. Navigate to `http://dockhand.${DOMAIN}`
2. The UI will be available immediately (uses SQLite by default)
3. Optionally set up authentication (OIDC/SSO, LDAP, or local accounts) in Settings

### Docker Socket Access

Dockhand requires read access to the Docker socket at `/var/run/docker.sock`. This allows it to:
- Discover running containers
- Manage container lifecycle (start, stop, restart)
- Stream real-time logs and metrics
- Access container resources

The socket is mounted read-only (`ro`) to limit container's ability to modify Docker state.

## Environment Variables

| Variable | Source | Service | Default | Description |
|---|---|---|---|---|
| `TZ` | Global | dockhand | Inherited | Timezone from root `.env` |
| `DOMAIN` | Global | dockhand | Inherited | Base domain for Traefik routing |

**Source Legend:**
- **Global**: Defined in root `.env`, inherited automatically
- **Local**: Defined in app-specific `.env`

## Volumes & Networks

| Name | Type | Purpose |
|---|---|---|
| `home_dockhand_data` | Named Volume | Persistent storage for SQLite database, app settings, and user preferences |
| `home_network` | External Network | Bridge network for Traefik routing and inter-app communication |

The app also mounts the Docker socket as read-only:
- `/var/run/docker.sock:/var/run/docker.sock:ro` - Allows Dockhand to access Docker daemon

## Official Documentation

- [Dockhand Project](https://dockhand.pro/)
- [Quick Start Guide](https://dockhand.pro/#quick-start)
- [Features](https://dockhand.pro/#features)
- [Manual / Docs](https://dockhand.pro/manual/)
- [GitHub Repository](https://github.com/Finsys/dockhand)
