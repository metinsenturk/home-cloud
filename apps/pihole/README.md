# Pi-hole

Pi-hole provides network-wide DNS-based ad and tracker blocking for your home network, with a web admin UI for visibility and policy management.

## Services

| Service | Description |
|---------|-------------|
| `pihole` | DNS resolver and filtering engine with embedded web admin interface |

## Access

- Admin UI: `http://pihole.${PIHOLE_DOMAIN}`
- DNS Service: Host port `53` (TCP/UDP) for LAN clients

## Starting this App

### From the app folder:
```bash
cd apps/pihole
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-pihole
```

## Configuration

- Set your router or DHCP server to hand out the Docker host IP as primary DNS.
- Confirm your local `.env` values for `PIHOLE_WEBPASSWORD`, `PIHOLE_DNS_UPSTREAMS`, and `PIHOLE_DNS_LISTENING_MODE`.
- DHCP is intentionally disabled in this initial setup.
- To enable DHCP later, uncomment the DHCP port and `FTLCONF_dhcp_active` line in `docker-compose.yml`, then review Pi-hole DHCP network-mode guidance (bridge mode typically requires DHCP relay).

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|------------------------|-------------|
| `PIHOLE_DOMAIN` | Both | pihole | `${DOMAIN}` | Subdomain suffix used by Traefik route label |
| `PIHOLE_TZ` | Both | pihole | `${TZ}` | Timezone for logs/scheduled tasks |
| `PIHOLE_WEBPASSWORD` | Both | pihole | `${HOME_CLOUD_PASSWORD}` | Pi-hole admin/API password via `FTLCONF_webserver_api_password` |
| `PIHOLE_DNS_PORT` | Local | pihole | `53` | Host port mapped to container DNS port 53 (TCP/UDP) |
| `PIHOLE_DHCP_PORT` | Local | pihole | `67` | Optional host DHCP port mapping (currently commented out) |
| `PIHOLE_DNS_LISTENING_MODE` | Local | pihole | `ALL` | Sets `FTLCONF_dns_listeningMode`; `ALL` is recommended in Docker bridge deployments |
| `PIHOLE_DNS_UPSTREAMS` | Local | pihole | `1.1.1.1;1.0.0.1` | Upstream DNS resolvers (semicolon-separated) |
| `PIHOLE_ENABLE_DHCP` | Local | pihole | `false` | Optional DHCP toggle used if `FTLCONF_dhcp_active` is uncommented |

## Volumes & Networks

- Volume `home_pihole_data`: Persists Pi-hole configuration and databases at `/etc/pihole`.
- Network `home_network`: External shared network for Traefik routing and service discovery.

## Official Documentation

- https://docs.pi-hole.net/docker/
- https://docs.pi-hole.net/docker/configuration/
- https://docs.pi-hole.net/docker/dhcp/
- https://github.com/pi-hole/docker-pi-hole
