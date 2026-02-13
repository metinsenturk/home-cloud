# pgBackweb

pgBackweb is an effortless PostgreSQL backup management tool with a user-friendly web interface. It enables scheduled database backups, supports multiple storage destinations (local and S3), includes PGP encryption for sensitive data, and provides comprehensive monitoring and webhook notifications.

## Services

| Service | Description |
|---------|-------------|
| **pgbackweb-db** | PostgreSQL 16 database storing pgBackweb metadata and backup configurations |
| **pgbackweb** | Web-based backup management interface and scheduling engine |

## Access

pgBackweb is accessible at:
```
https://pgbackweb.${DOMAIN}
```

Initial login credentials are set during first access. Follow the in-app setup wizard to configure your first PostgreSQL connection and backup schedule.

## Starting this App

### From the app folder:
```bash
cd apps/pgbackweb
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-pgbackweb
```

## Configuration

### Required Setup

1. **Generate Encryption Key**: Edit `apps/pgbackweb/.env` and set a strong encryption key:
   ```bash
   openssl rand -base64 32
   ```
   Copy the output to `PBW_ENCRYPTION_KEY` in `.env`.

2. **Update Database Credentials**: Modify the PostgreSQL credentials in `.env`:
   - `PBW_DB_USER`: Username for pgBackweb's internal database
   - `PBW_DB_PASSWORD`: Strong password for the database user
   - `PBW_DB_NAME`: Database name (default: `pgbackweb_db`)
   - Ensure `PBW_POSTGRES_CONN_STRING` matches your credentials

3. **First Login**: After starting, pgBackweb will display a setup wizard. Create your initial admin account.

4. **Add PostgreSQL Servers**: In the web UI, add the PostgreSQL databases you want to backup. You can connect to:
   - Databases on the same network (e.g., if you have PostgreSQL in another app on `home_network`)
   - External PostgreSQL servers

### Backup Configuration

Once logged in, you can:
- **Schedule Backups**: Set up automated backup schedules (hourly, daily, weekly, monthly)
- **Configure Storage**: Choose between local storage (`/backups`) or S3-compatible destinations
- **Enable Encryption**: Use PGP encryption to protect sensitive backups
- **Set Retention Policies**: Define how long backups are kept
- **Configure Webhooks**: Get notifications on backup completion, failures, or health check issues

## Environment Variables

| Variable Name | Source | Service | Default/Example | Description |
|---------------|--------|---------|-----------------|-------------|
| `PBW_DB_USER` | Local (`.env`) | pgbackweb-db | `pgbackweb` | PostgreSQL username for pgBackweb's metadata database |
| `PBW_DB_PASSWORD` | Local (`.env`) | pgbackweb-db | `pgbackweb_secure_password` | PostgreSQL password (must be a strong password) |
| `PBW_DB_NAME` | Local (`.env`) | pgbackweb-db | `pgbackweb_db` | PostgreSQL database name for pgBackweb metadata |
| `PBW_ENCRYPTION_KEY` | Local (`.env`) | pgbackweb | N/A (secret) | Encryption key for sensitive data (generate with `openssl rand -base64 32`) |
| `PBW_POSTGRES_CONN_STRING` | Local (`.env`) | pgbackweb | `postgresql://user:pass@pgbackweb-db:5432/pgbackweb_db?sslmode=disable` | Connection string for pgBackweb's metadata database |
| `PBW_LISTEN_HOST` | docker-compose.yml | pgbackweb | `0.0.0.0` | Address pgBackweb listens on (required for Traefik routing) |
| `PBW_LISTEN_PORT` | docker-compose.yml | pgbackweb | `8085` | Port pgBackweb listens on |
| `TZ` | Global (root `.env`) | pgbackweb | `UTC` | Timezone for backup timestamps and scheduling |
| `DOMAIN` | Global (root `.env`) | pgbackweb | N/A | Your domain name (used for Traefik routing) |

## Volumes & Networks

| Name | Type | Mount Point | Description |
|------|------|-------------|-------------|
| `home_network` | Network | External Network | Traefik reverse proxy network for routing |
| `home_pgbackweb_network` | Network | Internal Network | Isolated network for communication between pgBackweb and its database |
| `home_pgbackweb_db_data` | Volume | `/var/lib/postgresql/data` | PostgreSQL database files and pgBackweb configuration |
| `home_pgbackweb_backups` | Volume | `/backups` | Local backup storage directory (used when storing backups locally) |

## Official Documentation

- [pgBackweb GitHub Repository](https://github.com/eduardolat/pgbackweb)
- [pgBackweb Installation Guide](https://github.com/eduardolat/pgbackweb#installation)
- [pgBackweb Features](https://github.com/eduardolat/pgbackweb#features)
