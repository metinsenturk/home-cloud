# Project Context: The Mini-Cloud (Traefik + Docker Compose)

You are an expert DevOps engineer assisting with a modular self-hosted infrastructure. 
The project uses a "Base + App" folder strategy to allow launching subsets of services.

## Architecture Principles
- **Reverse Proxy:** Traefik v3 (lives in `/base`).
- **Networking:** All public-facing containers must connect to the external bridge network `home_network`.
- **Modularity:** Each application must live in its own subdirectory under `/apps`.
- **Routing:** Use Subdomains (e.g., `appname.localhost`) via Traefik labels, NOT subpaths.
- **Service Discovery:** Traefik watches the Docker socket. Labels are the source of truth for routing.
- **Documentation:** Every service MUST include clear comments explaining WHY a setting is used.
- **Workflow:** ALWAYS provide a high-level plan or "Action List" before providing code.

## Standard Docker Compose Pattern
When generating a new app in `/apps/<name>/docker-compose.yml`, always follow this template:

1. **Internal Networking:** Use a private bridge for internal service-to-service talk.
2. **External Networking:** Connect the entry-point container to `home_network`.
3. **Labels:** Add Traefik labels to the entry-point container for routing:
   - `traefik.enable=true`
   - `traefik.http.routers.<name>.rule=Host('<name>.localhost')`
   - `traefik.http.services.<name>.loadbalancer.server.port=<port>`
4. Avoid using version key in `docker-compose.yml` (use the latest syntax).
5. Avoid hardcoding ports in the compose file; rely on Traefik for routing.
6. **Ordering:** Follow the strict key order: `image`, `container_name`, `restart`, `command`, `ports`, `networks`, `volumes`, `labels`, `environment`, `logging`, `healthcheck`, `depends_on`, `env_file`.
7. **Clean Interpolation:** Use `${VARIABLE}` without hardcoded fallbacks for any sensitive data.
8. **Network Attachment:** Public services must use `home_network`. Internal communication must use `home_<appname>_network`.

# Naming Conventions

- **Service Names:** Use lowercase letters and hyphens (e.g., `myapp`). If multiple services are needed, use `<appname>-<purpose>` (e.g., `myapp-db`).
- **Container Names:** Follow the pattern `<appname>` (e.g., `myapp`). If multiple containers are needed, use `<appname>_<purpose>` (e.g., `myapp_db`).
- **Network Names:** Use `home_<appname>_network` for internal networks (e.g., `home_myapp_network`).
- **Volume Names:** Use `home_<appname>_data` for persistent storage (e.g., `home_myapp_data`). If multiple volumes are needed, use `home_<appname>_<purpose>` (e.g., `home_myapp_db_data`).

# Creating a New Service: Action List
1. **Choose a Name:** Pick a unique name for your service (e.g., `myapp`).
2. **Create Directory:** Make a new folder under `/apps` (e.g., `/apps/myapp`).
3. **Write Docker Compose:** Create a `docker-compose.yml` in that folder following the standard pattern.
   - Prefer using latest official images when possible. (postgres:latest, redis:latest, etc.)
4. **README.md:** Create a `README.md` in the service folder with:
   - A brief description of the service.
   - Any specific configuration instructions (e.g., environment variables, volumes).
   - Any important notes about configuration or dependencies.
   - A link to the official documentation for the service (if applicable).
   - A brief explanation of all services used in the `docker-compose.yml` file and their roles.
   - The command to start the service:
     * From the app folder: `docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d`
     * From the root folder: `make up-<name>`
5. **Makefile Integration:** Add a new target in the root `Makefile` to allow starting this service with `make up-<name>` and `make down-<name>`.
6. **Environment Variables:** All environment variables should be defined in the root of the service directory in a `.env` file. Do not hardcode sensitive values in the `docker-compose.yml`.
   - **App-Specific `.env`:** Every app folder MUST contain a `.env` and `.env.example` if the compose file requires it.
   - **Strict No-Hardcoding Policy:** Never include actual passwords or keys in `docker-compose.yml`, even as "default" values in the `${VAR:-default}` syntax.
   - **The `.env` / `.env.example` Split:** * **`.env`**: Must be created in the app folder with **working default values** for non-sensitive items (like `DB_NAME` or `DB_USER`) and actual secrets for your local environment.
      * **`.env.example`**: Must be created with **placeholders** (e.g., `PASSWORD=your_password_here`) to serve as a template.
   - **Variable Source Truth:** The `docker-compose.yml` should only reference variables. If a default is needed for a non-sensitive item, define it in the local `.env` file rather than the YAML.

## Makefile Integration
- New services should be added as variables at the top of the root `Makefile`.
- The `Makefile` loads the root `.env` first, followed by the app-specific `.env`, meaning the app-specific values will override globals.
- Add a specific `up-<name>` target and include it in the `up-all` target.
- Add a specific `down-<name>` target and include it in the `down-all` target.

## Tech Stack Preferences
- **Logging:** Centralized via Dozzle (`logs.localhost`).
- **Updates:** Managed by Watchtower (no manual pulls).
- **Environment:** Use `${TZ}` and `${DOMAIN}` variables.
- **Constraints:** Always include log-rotation (max-size: 10m) for every service.