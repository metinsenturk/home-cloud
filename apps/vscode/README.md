# VS Code Server

VS Code Server is VS Code running on a remote server, accessible through a web browser. This container provides a browser-based IDE with persistent configuration and workspace storage.

**Key Features:**
- Code in your browser from any device with consistent dev environment
- Git integration via SSH keys
- Extensions installable via the VS Code UI
- Persistent configuration and workspace across container restarts

## Services

| Service | Description |
|---------|-------------|
| **vscode** | Primary VS Code Server service running on port 8443, accessible via HTTPS browser interface |

## Access

- **URL:** `https://vscode.${DOMAIN}` (e.g., `https://vscode.localhost`)
- **Authentication:** Password protected (uses global `HOME_CLOUD_PASSWORD`)
- **Method:** HTTPS via Traefik reverse proxy

## Starting this App

### From the app folder:
```bash
cd apps/vscode
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder (recommended):
```bash
make up-vscode
```

## Configuration

### Environment Variables

Set these in `apps/vscode/.env`:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PUID` | number | Global | User ID for file permissions (inherited from root `.env`) |
| `PGID` | number | Global | Group ID for file permissions (inherited from root `.env`) |
| `TZ` | string | Global | Timezone setting (inherited from root `.env`) |
| `PASSWORD` | string | Global | Web UI password (uses `HOME_CLOUD_PASSWORD` from root `.env`) |

### SSH/Git Configuration

For GitHub integration:

1. Inside the VS Code terminal, place SSH keys in:
   ```bash
   ls /config/.ssh/
   ```

2. Configure Git (in VS Code terminal):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

### VS Code Extensions

**To install extensions:**
1. Open VS Code → Extensions (left sidebar icon)
2. Search and install as normal
3. Extensions persist in the `home_vscode_config_data` volume

### Hashed Password (Optional Security)

For enhanced security, use a hashed password instead of plain text:

1. Generate hashed password:
   ```bash
   code-server --print-ip-password
   # Or follow code-server docs: https://github.com/cdr/code-server/blob/master/docs/FAQ.md#can-i-store-my-password-hashed
   ```

2. Set in `.env`:
   ```env
   HASHED_PASSWORD=your_hashed_password_here
   ```

## Volumes & Networks

| Volume | Mount Point | Purpose |
|--------|-------------|---------|
| `home_vscode_config_data` | `/config` | VS Code configuration, extensions, workspace, SSH keys, and all persistent data |
| `settings.json` (bind mount) | `/config/data/User/settings.json` | Pre-configured VS Code settings for Python environment (read-only) |

| Network | Purpose |
|---------|---------|
| `home_network` | External bridge network for Traefik routing and cross-app communication |

## Customizing VS Code Settings

The `settings.json` file is mounted as read-only and provides default configurations for:
- Detecting color scheme

## Notes

- **Workspace Location:** `/config/workspace` - your code and projects live here
- **Extensions Persist:** All extensions installed are saved in the Docker volume
- **SSL Certificate:** Uses self-signed certificate for HTTPS; browser will warn (safe to ignore)
- **Traefik Routing:** No direct port mapping; access only via `vscode.localhost` through Traefik reverse proxy

## Official Documentation

- **Code-Server:** https://coder.com/docs/code-server/latest
- **VS Code Extensions:** https://marketplace.visualstudio.com/
- **LinuxServer Image:** https://docs.linuxserver.io/images/docker-code-server/
