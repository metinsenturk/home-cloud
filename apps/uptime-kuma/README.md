# Uptime Kuma

A fancy, self-hosted uptime monitoring tool. Monitor HTTP(s), TCP, DNS, ICMP ping, and 90+ notification services.

## Services

- **uptime-kuma**: Web-based monitoring dashboard and alert service. Stores monitoring data and configurations in an internal SQLite database.

## Access

- **URL**: `http://kuma.${DOMAIN}`
- **First Access**: On first startup, you'll be guided through the setup wizard to create your admin account and configure monitoring targets.

## Starting this App

### From the app folder:
```bash
cd apps/uptime-kuma
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-uptime-kuma
```

## Configuration

**No advanced configuration required.** All settings are managed through the web UI:

1. On first access, create your admin account.
2. Add monitors for services, websites, or infrastructure you want to track.
3. Configure notifications (Telegram, Discord, Email, Slack, etc.) from the settings.
4. Create status pages to share uptime status publicly.

The application uses an internal SQLite database (`/app/data/kuma.db`) for persistent storage.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---|---|---|---|---|
| `TZ` | Global | uptime-kuma | `UTC` | Timezone for the application |
| `DOMAIN` | Global | uptime-kuma | `localhost` | Domain used in Traefik routing (e.g., `kuma.example.com`) |

## Volumes & Networks

| Name | Type | Purpose |
|---|---|---|
| `home_uptime_kuma_data` | Volume | Persistent storage for SQLite database and monitoring data |
| `home_network` | Network | External bridge network for Traefik routing |

## Official Documentation

- [Uptime Kuma GitHub Repository](https://github.com/louislam/uptime-kuma)
- [Installation & Configuration Wiki](https://github.com/louislam/uptime-kuma/wiki/%F0%9F%94%A7-How-to-Install)
- [Notification Services Guide](https://github.com/louislam/uptime-kuma/tree/master/src/components/notifications)
