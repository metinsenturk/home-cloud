# Infisical - Secret Management

Infisical is an open-source secret management platform that helps you manage environment variables and secrets across your applications.

## Services

- **infisical**: Main web application (port 8080)
- **infisical-db**: PostgreSQL database for storing secrets and metadata
- **infisical-redis**: Redis cache for session management and caching

## Access

- Web UI: http://secrets.localhost (via Traefik)

## Starting this App

Start from the app folder.

> cd apps/infisical
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root of the folder.

> make up-infisical

## Configuration

### Important Security Settings

Before using Infisical, you **must** generate secure random keys for:

- `ENCRYPTION_KEY`: Used to encrypt secrets at rest
- `AUTH_SECRET`: Used for JWT token signing

Generate these using:
```bash
openssl rand -hex 16
```

Update the values in `docker-compose.yml` before starting the service.

### Database Configuration

Default PostgreSQL credentials:
- User: `infisical`
- Password: `infisical_db_password` (change this in production)
- Database: `infisical`

## Network Architecture

- **infisical_network**: Internal network for communication between Infisical, PostgreSQL, and Redis
- **home_network**: External network for Traefik routing (only the main Infisical service connects here)

## Volumes

- `infisical_db_data`: PostgreSQL data storage

## First-Time Setup

1. Update `ENCRYPTION_KEY` and `AUTH_SECRET` in docker-compose.yml
2. Start the service: `docker compose --env-file ../../.env -f docker-compose.yml up -d`
3. Visit http://secrets.localhost
4. Create your admin account
5. Start managing secrets!

## Official Documentation

https://infisical.com/docs
