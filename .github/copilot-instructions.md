# Project Context: The Mini-Cloud (Traefik + Docker Compose)

You are an expert DevOps engineer assisting with a modular self-hosted infrastructure. 
The project uses a "Base + App" folder strategy to allow launching subsets of services.

## Architecture Principles
- **Reverse Proxy:** Traefik v3 (lives in `/base`).
- **Networking:** All public-facing containers must connect to the external bridge network `home_network`.
- **Modularity:** Each application must live in its own subdirectory under `/apps`.
- **Routing:** Use Subdomains (e.g., `appname.${DOMAIN}`) via Traefik labels, NOT subpaths.
- **Service Discovery:** Traefik watches the Docker socket. Labels are the source of truth for routing.
- **Documentation:** Every service MUST include clear comments explaining WHY a setting is used.
- **Workflow:** ALWAYS provide a high-level plan or "Action List" before providing code.

## Infrastructure & Shared Services Pattern
- **Service Naming (Dashes):** Use `infra-` prefix with dashes (e.g., e.g., `infra-postgres`, `infra-mssql`). This acts as the internal DNS hostname.
- **Folder Naming (Underscores):** Use `infra_` prefix with underscores (e.g., `infra_postgres`, `infra_mssql`).
- **Container Naming (Underscores):** Use `infra_` prefix with underscores (e.g., `infra_postgres`, `infra_mssql`).
- **Persistence & Networking (Underscores):** Strictly follow these patterns:
    - Network: `home_infra_<name>_network`
    - Volume: `home_infra_<name>_data`
- **Connectivity:** - Always attach to `home_network` for cross-app discovery.
    - Set `traefik.enable=false` (Infrastructure is accessed via Service Name, not URLs).
- **Global Variables:** Inherit `TZ` and `DOMAIN` from the root `.env`. Do not duplicate them in app-local `.env` files.

## Service Lifecycle & Discovery
- **New Service Protocol:** Every new application is treated as a modular "plug-in" to the existing Mini-Cloud. It must be research-validated (images, ports, entrypoints) before code generation.
- **Task-Specific Execution:** Detailed scaffolding of new apps is handled via the `/add-app` prompt. Always refer to `.github/prompts/add-app.prompt.md` for the multi-step research and confirmation workflow.
- **Binding Rule:** Services must never listen on `127.0.0.1` inside the container; they must bind to `0.0.0.0` to ensure the Traefik proxy on the `home_network` can reach them.
- **Connectivity Check:** If a service has multiple networks, the Traefik routing label MUST explicitly specify `traefik.docker.network=home_network` to prevent 504 Gateway Timeouts.

## Standard Docker Compose Pattern
When generating a new app in `/apps/<name>/docker-compose.yml`, always follow this template:

1. **External Networking:** Connect the entry-point container to `home_network`.
2. **Internal Networking:** Use a private bridge for internal service-to-service talk if needed.
3. **Labels:** Add Traefik labels to the entry-point container for routing:
   - `traefik.enable=true`
   - `traefik.http.routers.<name>.rule=Host(`<name>.${DOMAIN}`)`
   - `traefik.http.services.<name>.loadbalancer.server.port=<port>`
4. **Multi-Network Routing:** If a container is connected to more than one network, you **MUST** explicitly tell Traefik which network to use for routing to avoid 504 errors.
   - **Label:** `- "traefik.docker.network=home_network"`
5. Avoid using version key in `docker-compose.yml` (use the latest syntax).
6. Avoid hardcoding ports in the compose file; rely on Traefik for routing.
7. **Ordering:** Follow the strict key order: `image`, `container_name`, `restart`, `networks`, `volumes`, `labels`, `environment`, `logging`, `healthcheck`, `depends_on`, `env_file`.
8. **Clean Interpolation:** Use `${VARIABLE}` without hardcoded fallbacks. 
   - **Inheritance:** Assume global variables like `TZ` and `DOMAIN` are already available from the root `.env`. Do not duplicate them into app-specific environment files.
   - **Local Defaults:** Define app-specific defaults in the local `/apps/<name>/.env` file.
9. **Network Attachment:** Public services must use `home_network`. Internal communication must use `home_<appname>_network`.
10. **Explicit Naming**: To prevent Docker Compose from adding folder-name prefixes to resources, always use the `name:` attribute for local networks and volumes. See example below.
```yaml
networks:
  home_myapp_network:
    name: home_myapp_network
    driver: bridge
```
11. **Logging:** Always include log-rotation (max-size: 10m) for every service. Json logging is preferred for better integration with Dozzle.
12. **Healthchecks:** Always include a healthcheck for each service to allow Traefik to detect unhealthy containers and avoid routing to them. Use the `interval`, `timeout`, `retries`, and `start_period` options to fine-tune the healthcheck behavior.
13. **Documentation:** Include comments in the `docker-compose.yml` explaining the purpose of each setting, especially for non-obvious configurations. Comments about global architectural decisions (`home_network`, Traefik labels, Global environment variables, etc.) should be included in the root README rather than individual compose files to avoid redundancy.

# Naming Conventions

- **Folder Names:** Use lowercase letters and underscores. If the app name is multiple words, use underscores (e.g., `myapp`, `my_app`).
- **Service Names:** Use lowercase letters and hyphens (e.g., `myapp`). If multiple services are needed, use `<appname>-<purpose>` (e.g., `myapp-db`).
- **Container Names:** Follow the pattern `<appname>` (e.g., `myapp`). If multiple containers are needed, use `<appname>_<purpose>` (e.g., `myapp_db`).
- **Network Names:** Use `home_<appname>_network` for internal networks (e.g., `home_myapp_network`).
- **Volume Names:** Use `home_<appname>_data` for persistent storage (e.g., `home_myapp_data`). If multiple volumes are needed, use `home_<appname>_<purpose>` (e.g., `home_myapp_db_data`).

# Coding Style

- When defining networks, define `home_network` first, then internal networks.
- When defining volumes, define `home_<appname>_data` first, then any additional volumes.

## Makefile Integration
* **App-Specific Targets:** Every new app must have its own `up-` and `down-` targets.
* **No Top-Level Variables:** Do not define app paths as variables at the top. Use the direct path within the command.
* **The "Double-Env" Pattern:** All app targets must explicitly load the root `.env` first, then the local `.env`, meaning the app-specific values will override globals.
* **Standard Format:**
```makefile
.PHONY: up-appname
up-appname: create-network
	docker compose --env-file .env --env-file apps/appname/.env -f apps/appname/docker-compose.yml up -d

.PHONY: down-appname
down-appname:
	docker compose --env-file .env --env-file apps/appname/.env -f apps/appname/docker-compose.yml down

```
* **Orchestration:** Add new apps to the `up-all` and `down-all` aggregate targets.

## Port Registry (PORTS.md)
- **Purpose:** A centralized log of all host-accessible ports to prevent conflicts.
- **Central Registry:** All ports exposed to the host MUST be documented in `/PORTS.md`.
- **Content:** Includes the host port, the service name, the internal container port, and a brief description.
- **Update Rule:** When adding a new host-exposed port, append a single row to the existing table in `/PORTS.md`. Do not rewrite the file or add extra commentary.
- **Structure:** 
   - `# Host Ports`: Brief description of the file's purpose.
   - `## Ports Table`: A Markdown table with columns: `Host Port`, `Service Name`, `Internal Port`, `Description`.
   - `## Notes`: A list of specific operational notes referencing the table entries.
- **Mapping Style:** Prefer consistent mapping (e.g., `5432:5432`) unless a conflict exists on the host.
- **Conflict Prevention:** Before assigning a host port to a new service, check `/PORTS.md` to ensure it is not already in use.

## Tech Stack Preferences
- **Logging:** Centralized via Dozzle (`logs.localhost`).
- **Updates:** Managed by What's Up Docker (WUD) (no manual pulls).
- **Environment:** Use `${TZ}` and `${DOMAIN}` variables.
- **Constraints:** Always include log-rotation (max-size: 10m) for every service.