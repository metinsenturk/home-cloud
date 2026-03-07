# Homebridge

Homebridge is a lightweight NodeJS server that emulates the iOS HomeKit API, allowing you to integrate smart home devices that don't natively support HomeKit with Apple Home.

## Services

| Service | Description |
|---------|-------------|
| **homebridge** | Main Homebridge server with web UI for managing plugins and accessories |

## Access

- **Web UI:** `http://homebridge.${DOMAIN}` (routed through Traefik)
- **HomeKit Bridge:** Port 51826 (exposed to host for iOS device connectivity)
- **Default Login:** `admin` / `admin` (change immediately on first login)

## HomeKit Discovery

**Platform-Specific Setup Required**

See [DISCOVERY.md](DISCOVERY.md) for detailed platform guidance:
- **Linux/macOS**: Automatic discovery supported with port mapping
- **Windows**: Manual pairing required due to mDNS port conflicts

## Starting this App

### From the app folder:
```bash
cd apps/homebridge
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-homebridge
```

## Configuration

### Initial Setup
1. Access the web UI at `http://homebridge.${DOMAIN}`
2. Log in with default credentials: `admin` / `admin`
3. Change the default password immediately
4. Install plugins via the web UI as needed
5. Configure devices and accessories through the web interface

### HomeKit Pairing
1. Open the Apple Home app on your iOS device
2. Tap "Add Accessory"
3. Scan the QR code displayed in the Homebridge web UI
4. Enter the 8-digit PIN if prompted (also shown in the web UI)

### Plugin Management
- Install plugins directly from the web UI under "Plugins"
- Configure plugin settings through the web interface
- Restart Homebridge after installing or updating plugins

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|----------------------|-------------|
| `TZ` | Global | homebridge | `UTC` | Timezone for logs and scheduling |
| `PUID` | Global | homebridge | `1000` | User ID for file permissions |
| `PGID` | Global | homebridge | `1000` | Group ID for file permissions |
| `DOMAIN` | Global | homebridge | N/A | Domain for Traefik routing |
| `HOMEBRIDGE_CONFIG_UI` | docker-compose.yml | homebridge | `1` | Enable web configuration UI |
| `HOMEBRIDGE_CONFIG_UI_PORT` | docker-compose.yml | homebridge | `8581` | Web UI port (internal) |

## Volumes & Networks

### Volumes
- **home_homebridge_data**: Persistent storage for Homebridge configuration, plugins, and accessories (`/homebridge`)

### Networks
- **home_network**: External network for Traefik routing and cross-app communication

### Ports
- **51826** (TCP): Exposed to host for HomeKit bridge functionality (required for iOS device discovery)
- **8581** (TCP): Web UI port (accessed via Traefik, not exposed to host)

## Notes

- **mDNS Discovery**: The container handles Bonjour/mDNS advertising for HomeKit discovery
- **Plugin Ecosystem**: Thousands of plugins available for various smart home platforms (Nest, Ring, TP-Link, etc.)
- **Backup**: Configuration is stored in the `home_homebridge_data` volume - back up regularly
- **Performance**: Lightweight - typically uses < 100MB RAM with a few plugins
- **Updates**: Container updates are managed by What's Up Docker (WUD)

## Official Documentation

- **Homebridge:** https://homebridge.io/
- **Docker Image:** https://github.com/homebridge/docker-homebridge
- **Plugin Directory:** https://www.npmjs.com/search?q=homebridge-plugin
