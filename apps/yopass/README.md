# Yopass - Share Secrets Securely

Yopass is a web application for sharing secrets, passwords, and files in a quick and secure manner. Messages are encrypted/decrypted locally in the browser using OpenPGP and sent to Yopass without the decryption key. Yopass returns a one-time URL with a specified expiry date, ensuring secrets self-destruct after a configured time.

## Services

- **yopass**: The main web application (frontend + backend API). Listens on port 1337. Handles encryption, secret storage coordination, and the web UI for sharing secrets.
- **yopass-memcached**: In-memory data store for encrypted secrets. Uses Memcached for fast, temporary secret storage. Secrets are lost on restart unless persistence is added.

## Access

Once deployed, access Yopass at:
```
https://yopass.${DOMAIN}
```

Example: `https://yopass.localhost` (if DOMAIN=localhost)

## Starting this App

### From the app folder:
```bash
cd apps/yopass
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-yopass
```

## Configuration

Yopass works out-of-the-box with sensible defaults. No additional configuration is required beyond the inherited global variables (`TZ` and `DOMAIN`).

### Optional Customization

If you need to customize Yopass behavior, you can pass additional command-line flags via the `docker-compose.yml`:

- `--port`: Change the listen port (default: 1337)
- `--max-length`: Maximum secret length in characters (default: 10000)
- `--force-onetime-secrets`: Reject non-one-time secrets from being created
- `--disable-upload`: Disable file upload endpoints
- `--disable-features`: Hide the features section on the frontend
- `--trusted-proxies`: Configure trusted proxy IPs for X-Forwarded-For headers

Example modification to enforce one-time secrets only:
```yaml
yopass:
  image: jhaals/yopass:latest
  # ... other config ...
  command: --force-onetime-secrets
```

## Environment Variables

| Variable Name | Source | Service | Default/Example | Description |
|---|---|---|---|---|
| TZ | Global | yopass, yopass-memcached | UTC | Timezone for container (inherited from root `.env`) |
| DOMAIN | Global | yopass | localhost | Domain for subdomain routing (inherited from root `.env`) |

**Notes:**
- All global variables are inherited from the root `.env` via the Makefile's "Double-Env" pattern.
- This app requires no additional configuration beyond the inherited globals.

## Volumes & Networks

### Networks

- **home_network** (external): Connected for Traefik routing and global service discovery.
- **home_yopass_network** (internal): Private bridge network for yopass ↔ memcached communication. Excludes external access.

### Volumes

- **None for yopass**: Secrets are ephemeral and stored in Memcached.
- **Memcached (in-memory)**: By default, secrets are stored in RAM and lost on restart. To persist secrets across restarts, mount a volume to Memcached (advanced configuration; see Memcached documentation).

## Storage Architecture

- **Default (No Persistence)**: Secrets are stored in Memcached's RAM. On container restart, all secrets are deleted. This is the recommended default for security.
- **Optional Persistence**: If you require secrets to survive container restarts, you can configure Memcached with persistent storage (e.g., Redis backend instead of Memcached, or external database).

## Official Documentation

- **Yopass GitHub**: https://github.com/jhaals/yopass
- **Yopass Official Demo**: https://yopass.se
- **Docker Hub**: https://hub.docker.com/r/jhaals/yopass
