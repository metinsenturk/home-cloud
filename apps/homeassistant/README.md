# Home Assistant

Home Assistant is an open-source home automation platform that focuses on privacy and local control. It integrates with thousands of smart home devices and services to create a unified smart home experience.

## Services

| Service | Description |
|---------|-------------|
| **homeassistant** | Main Home Assistant server with web UI for managing automations, devices, and integrations |

## Access

- **Web UI:** `http://homeassistant.${DOMAIN}` (routed through Traefik)
- **First-Time Setup:** Create an owner account on first access

## Starting this App

### From the app folder:
```bash
cd apps/homeassistant
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-homeassistant
```

## Configuration

### Initial Setup

#### First-Time Configuration (Important!)
On first access, you may see a "400 Bad Request" error. This is because Home Assistant needs to trust the Traefik reverse proxy. Follow these steps:

1. **Stop the container**: `make down-homeassistant`
2. **Create configuration file** in the persistent volume:
   ```bash
   docker run --rm -v home_homeassistant_data:/config alpine sh -c "cat > /config/configuration.yaml << 'EOF'
   # Loads default set of integrations. Do not remove.
   default_config:

   # HTTP configuration for reverse proxy
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 172.24.0.0/16  # Docker home_network subnet
   EOF"
   ```
3. **Restart**: `make up-homeassistant`
4. **Access** the web UI at `http://homeassistant.${DOMAIN}`
5. **Create your owner account** (first user becomes admin)
6. **Set your home location** and unit system
7. **Begin adding integrations** for your smart home devices

**Alternative:** If you prefer, you can access Home Assistant directly via `docker exec homeassistant nano /config/configuration.yaml` after starting the container for the first time.

### Adding Integrations
1. Navigate to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for your device/service (Philips Hue, MQTT, Zigbee, etc.)
4. Follow the setup wizard for each integration

### USB Device Access (Optional)
If you need to connect USB devices (Zigbee/Z-Wave dongles), you'll need to:
1. Stop the container: `make down-homeassistant`
2. Add device mapping to `docker-compose.yml`:
   ```yaml
   devices:
     - /dev/ttyUSB0:/dev/ttyUSB0  # Adjust device path as needed
   ```
3. May need `privileged: true` for some devices
4. Restart: `make up-homeassistant`

### Configuration Files
All configuration is stored in the persistent volume at `/config`. Key files:
- `configuration.yaml` - Main configuration file
- `automations.yaml` - Automation definitions
- `scripts.yaml` - Script definitions
- `secrets.yaml` - Sensitive values (API keys, passwords)

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|----------------------|-------------|
| `TZ` | Global | homeassistant | `UTC` | Timezone for logs, automations, and scheduling |
| `DOMAIN` | Global | homeassistant | N/A | Domain for Traefik routing |

## Volumes & Networks

### Volumes
- **home_homeassistant_data**: Persistent storage for Home Assistant configuration, database, and user data (`/config`)

### Networks
- **home_network**: External network for Traefik routing and cross-app communication

## Notes

- **First Boot**: Initial startup may take 2-3 minutes as Home Assistant initializes
- **Updates**: Container updates are managed by What's Up Docker (WUD)
- **Database**: Uses SQLite by default; can be configured to use PostgreSQL or MariaDB for better performance
- **Backups**: Configuration is stored in the `home_homeassistant_data` volume - back up regularly
- **Mobile App**: Available for iOS and Android with push notifications and location tracking
- **Device Discovery**: mDNS discovery may be limited in bridge network mode; some integrations might require manual IP configuration
- **HTTPS**: Web UI is accessed via Traefik; Home Assistant's internal HTTPS is not required

## Integrations with Other Apps

### MQTT (if using MQTT broker)
Home Assistant can connect to an MQTT broker for IoT device communication. Configure in **Settings** → **Devices & Services** → **MQTT**.

### PostgreSQL (optional)
For better performance with large installations, you can configure Home Assistant to use the `infra-postgres` database:
1. Add to `configuration.yaml`:
   ```yaml
   recorder:
     db_url: postgresql://user:password@infra-postgres:5432/homeassistant
   ```
2. Create the database: `docker exec infra_postgres psql -U postgres -c "CREATE DATABASE homeassistant;"`

## Official Documentation

- **Home Assistant:** https://www.home-assistant.io/
- **Installation Guide:** https://www.home-assistant.io/installation/
- **Docker Installation:** https://www.home-assistant.io/installation/linux#install-home-assistant-container
- **Integrations:** https://www.home-assistant.io/integrations/
