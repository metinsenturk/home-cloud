# Duplicati

Duplicati is an encrypted backup service with a web UI for scheduling and managing backups to local and cloud destinations.

## Services

- **duplicati** – Web backup service that stores app state in a persistent `/data` volume.

## Access

- **Web UI:** `http://duplicati.${DOMAIN}`

## Starting this App

From the app folder:
```bash
cd apps/duplicati
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

From the root folder:
```bash
make up-duplicati
```

## Configuration

- Set `DUPLICATI_PASSWORD` in `apps/duplicati/.env` (mapped to `${HOME_CLOUD_PASSWORD}` by default).
- Keep `DUPLICATI_ALLOWED_HOSTNAMES=duplicati.localhost` unless you intentionally allow additional hostnames.
- Add backup source mounts in `docker-compose.yml` when you decide which host paths to back up.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `DUPLICATI_PASSWORD` | Both | `duplicati` | `${HOME_CLOUD_PASSWORD}` | Web UI password variable used by `DUPLICATI__WEBSERVICE_PASSWORD`. |
| `DUPLICATI_ALLOWED_HOSTNAMES` | Local | `duplicati` | `duplicati.localhost` | Host header allowlist for web access; use explicit `;`-separated hostnames and avoid `*` unless required. |
| `TZ` | Global | `duplicati` | `UTC` | Container timezone for logs and scheduling behavior. |

## Volumes & Networks

- **Volume:** `home_duplicati_data` stores Duplicati configuration and database under `/data`.
- **Network:** `home_network` enables Traefik routing to this service.

## Official Documentation

- [Duplicati Documentation](https://docs.duplicati.com/)
- [Duplicati Docker Hub](https://hub.docker.com/r/duplicati/duplicati)
