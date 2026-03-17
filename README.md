# Home Cloud 🏠☁️

A **modular, self-hosted infrastructure** built with **Traefik** and **Docker Compose**. Run your own suite of applications with make commands, all routed through a single Traefik entry point. Perfect for home labs, small businesses, or anyone looking to take control of their digital ecosystem.

## Overview

Home Cloud is a production-ready orchestration framework for deploying and managing multiple interconnected Docker services. Use it to run dashboards, databases, automation tools, and more through a unified Traefik entry point.

**Key Features:**
- 🔄 **Modular Architecture**: Add/remove apps independently without affecting others
- 🔐 **Centralized Routing**: Traefik provides a single entry point for your services
- 🌐 **Subdomain Routing**: Access apps via `appname.yourdomain.com` (not `/appname` paths)
- 📦 **Docker Compose**: Standard Docker tooling—no Kubernetes required
- ⚡ **Easy Management**: Simple Make commands orchestrate everything
- 🛠️ **Flexible Configuration**: Use Make or YAML group files for command organization

## Quick Start

### 1. Prerequisites

- **Docker** and **Docker Compose** (v2+)
- **Git** for cloning the repository
- A **domain name** pointing to your server
- **GNU Make** (comes with most Linux systems; on WSL, install via `apt-get install make`)

### 2. Clone & Setup

```bash
# Clone the repository
git clone <your-repo-url> home-cloud
cd home-cloud

# Create your local configuration from the template
make init-env
```

This creates a `.env` file with all necessary global variables (timezone, domain, credentials, etc.).

### 3. Configure Your Environment

Edit the `.env` file and set your values:

```bash
# Essential variables
DOMAIN=example.com          # Your domain name
TZ=UTC                      # Your timezone
PUID=1000                   # Linux UID (for file permissions)
PGID=1000                   # Linux GID (for file permissions)

# Global credentials (used by shared services)
HOME_CLOUD_EMAIL=admin@example.com
HOME_CLOUD_PASSWORD=securepassword
INFRA_POSTGRES_PASSWORD=dbpassword
```

See [`.env.example`](.env.example) for all available options.

### 4. Start the Core Infrastructure

```bash
# Create the shared network that all apps use
make create-network

# Launch core services (Traefik, Dozzle, WUD)
make up-base
```

Once core services are running, Traefik is available at `https://traefik.yourdomain.com`.

### 5. Launch Your First App

```bash
# See available commands
make list-groups

# Start an app (e.g., Dozzle for log viewing)
make up-dozzle

# Visit https://dozzle.yourdomain.com
```

## Project Structure

```
home-cloud/
├── Makefile                 # Main command orchestration
├── MAKEFILE.md             # Makefile documentation
├── PORTS.md                # Port registry (prevent conflicts)
├── .env.example            # Configuration template
├── apps/                   # Individual applications
│   ├── traefik/            # Reverse proxy (base service)
│   ├── dozzle/             # Centralized log viewer (base service)
│   ├── wud/                # Update detector (base service)
│   ├── infra_postgres/     # Shared PostgreSQL database
│   ├── metabase/           # Data visualization
│   ├── jupyter/            # Jupyter notebooks
│   └── ... (40+ apps)
└── briefs/                 # Knowledge base documents
```

## Common Commands

A few examples to get you started. For a complete command reference, see [**MAKEFILE.md**](MAKEFILE.md).

```bash
# Setup & Validation
make init-env                    # Create .env from template
make install-optional-tools      # Install bats, yq, parallel, git
make check-tools                 # Verify required dependencies

# Launching & Stopping
make up-base                     # Start Traefik and base services
make up-<appname>               # Start a specific app
make up-all                      # Start everything (use with caution!)
make down-<appname>             # Stop a specific app
make down-all                    # Stop everything

# Management
make list-groups                 # Show all available apps
make ps                          # Docker compose ps for all services
make logs-<appname>             # View live logs for an app

# Testing & Troubleshooting
make test-all                    # Run test suite
make check-ports                 # Verify port conflicts
```

## Adding a New App

To add a custom application to your Home Cloud:

1. Create a folder under `apps/`:
   ```bash
   mkdir apps/myapp
   ```

2. Create `docker-compose.yml` with your service definition. Ensure it:
   - Connects to the external `home_network` for Traefik routing
   - Uses Traefik labels to expose the service via your domain
   - Includes a healthcheck for monitoring

3. Create a local `.env` file if your app needs configuration:
   ```bash
   touch apps/myapp/.env
   ```

4. Add Make targets to the `Makefile`:
   ```makefile
   .PHONY: up-myapp
   up-myapp: create-network
   	docker compose --env-file .env --env-file apps/myapp/.env -f apps/myapp/docker-compose.yml up -d

   .PHONY: down-myapp
   down-myapp:
   	docker compose --env-file .env --env-file apps/myapp/.env -f apps/myapp/docker-compose.yml down
   ```

For a detailed walkthrough on app structure and Traefik configuration, see the [copilot-instructions.md](.github/copilot-instructions.md).

## Shared Services

Some apps are considered **shared infrastructure** and can be used by other applications:

- **PostgreSQL** (`infra_postgres/`): Database backend for multiple apps
- **MongoDB** (`infra_mongodb/`): NoSQL database
- **MSSQL** (`infra_mssql/`): Microsoft SQL Server
- **Redis**: In-memory cache (if configured)

To use a shared service, reference it by its service name (e.g., `infra-postgres:5432`).

## Networking & Routing

All public-facing apps route through **Traefik**, which:
- Listens on ports **80** (HTTP) and **443** (HTTPS)
- Auto-discovers apps via Docker labels
- Routes HTTP and HTTPS traffic based on your Traefik configuration
- Routes based on hostnames (subdomains)

**Example**: An app with the label `traefik.http.routers.myapp.rule=Host(myapp.yourdomain.com)` will be accessible at `https://myapp.yourdomain.com`.

See [PORTS.md](PORTS.md) for the full port registry and [apps/traefik/README.md](apps/traefik/README.md) for Traefik configuration details.

## Configuration Management

### Global Configuration (`.env`)

The `.env` file defines global variables used by all apps:

```bash
DOMAIN=example.com          # Shared domain for routing
TZ=UTC                      # Shared timezone
PUID/PGID=1000             # Shared user/group IDs
HOME_CLOUD_*               # Global credentials
INFRA_*                    # Shared service passwords
```

### Local Configuration (per app)

Each app can have its own `.env` file under `apps/<appname>/.env`. App-specific values override globals.

**Example**: An app might define `MYAPP_LOGLEVEL=debug` locally, while sharing the global `DOMAIN` and `TZ`.

## Logs & Monitoring

### View Logs
```bash
# Dozzle (web-based log viewer)
# Available at https://dozzle.yourdomain.com

# Command-line logs
make logs-<appname>
```

### Monitor Services
```bash
# See all running containers
make ps

# Check health status of a specific app
docker compose -f apps/dozzle/docker-compose.yml ps
```

## Troubleshooting

### Port Conflicts
Check [PORTS.md](PORTS.md) to see which ports are in use. If you encounter a conflict:
1. Verify no other service is using that port: `lsof -i :<port>`
2. Update the `Makefile` target to use a different port
3. Document the change in `PORTS.md`

### Service Won't Start
```bash
# Check logs
make logs-<appname>

# Verify health status
docker compose -f apps/myapp/docker-compose.yml ps

# Inspect configuration
cat apps/myapp/docker-compose.yml
cat apps/myapp/.env
```

### Traefik Not Routing
- Ensure the app container is on the `home_network`: Check the `networks:` section in its `docker-compose.yml`
- Verify Traefik labels are correct: Use `docker inspect <container>` to see the labels
- Check Traefik dashboard: `https://traefik.yourdomain.com`

## Project Configuration Files

- **[Makefile](Makefile)** – Command orchestration (see [MAKEFILE.md](MAKEFILE.md) for docs)
- **[.env.example](.env.example)** – Configuration template
- **[PORTS.md](PORTS.md)** – Port registry and conflict prevention
- **[MAKEFILE.md](MAKEFILE.md)** – Complete Makefile guide with all commands and options
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** – Architecture and development guidelines

## Tips & Best Practices

- **Use group files for organization**: Instead of running individual `make up-*` commands, organize related apps into group files (`.env` variable `HOME_CLOUD_GROUPS_BACKEND` controls this). See [MAKEFILE.md](MAKEFILE.md#-working-with-groups) for details.
- **Keep `.env` secure**: Add `.env` to `.gitignore` (already done). Never commit sensitive credentials.
- **Test before deploying**: Use `make -n <command>` for a dry-run to see what will execute.
- **Use healthchecks**: All services should include `healthcheck:` in their `docker-compose.yml` for automatic failure detection.
- **Log rotation**: Always include `logging:` with `max-size` to prevent log files from consuming disk space.

## Next Steps

1. **Complete the setup**: `make init-env` → configure `.env` → `make create-network` → `make up-base`
2. **Install optional tools** (for group file support): `make install-optional-tools`
3. **Explore available apps**: `make list-groups`
4. **Read the detailed guides**:
   - [MAKEFILE.md](MAKEFILE.md) – All Make commands and options
   - [.github/copilot-instructions.md](.github/copilot-instructions.md) – Architecture details

## License & Contributions

See `LICENSE` file. Contributions welcome!

---

**Questions?** Check the [MAKEFILE.md](MAKEFILE.md) or review the app-specific `README.md` files in each `apps/<appname>/` directory.
