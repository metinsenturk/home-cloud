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
* **Multi-Network Routing:** If a container is connected to more than one network, you **MUST** explicitly tell Traefik which network to use for routing to avoid 504 errors.
  * **Label:** `- "traefik.docker.network=home_network"`
4. Avoid using version key in `docker-compose.yml` (use the latest syntax).
5. Avoid hardcoding ports in the compose file; rely on Traefik for routing.
6. **Ordering:** Follow the strict key order: `image`, `container_name`, `restart`, `command`, `ports`, `networks`, `volumes`, `labels`, `environment`, `logging`, `healthcheck`, `depends_on`, `env_file`.
7. **Clean Interpolation:** Use `${VARIABLE}` without hardcoded fallbacks for any sensitive data.
8. **Network Attachment:** Public services must use `home_network`. Internal communication must use `home_<appname>_network`.
9. **Explicit Naming**: To prevent Docker Compose from adding folder-name prefixes to resources, always use the `name:` attribute for local networks and volumes. See example below.
```yaml
networks:
  home_myapp_network:
    name: home_myapp_network
    driver: bridge
```
10. **Logging:** Always include log-rotation (max-size: 10m) for every service. Json logging is preferred for better integration with Dozzle.
11. **Healthchecks:** Always include a healthcheck for each service to allow Traefik to detect unhealthy containers and avoid routing to them. Use the `interval`, `timeout`, `retries`, and `start_period` options to fine-tune the healthcheck behavior.
12. **Documentation:** Include comments in the `docker-compose.yml` explaining the purpose of each setting, especially for non-obvious configurations.

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
   - Only the following sections: Services, Access, Starting this App, Configuration, Environment Variables, Volumes & Networks (if applicable), Official Documentation.
   - **Services:** List all services defined in the `docker-compose.yml` with a brief description of their role.
   - **Access:** Provide the URL for accessing the service (e.g., `http://myapp.localhost`).
   - **Starting this App:** Provide clear instructions on how to start the service in two ways, from app folder and from root:
      * From the app folder: `cd apps/<name>` and `docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d`
      * From the root folder: `make up-<name>`
   - **Configuration:** Make a list of any important configuration steps or dependencies.
      * Any environment variables that need to be set in the local `.env`
      * Any app specific setup steps
      * Do not include any instructions that are not specific to this app (e.g., "make sure Traefik is running", "make sure `home_network` exists" is not needed if it's already in the root README).
   - **Environment Variables:** Create a table with the following columns listing all environment variables used:
      * Variable Name
      * Source (e.g., `.env`, `.env.example`): Values are Local, Global and Both. Local means the variable is only defined in the app's `.env`. Global means it's only defined in the root `.env`. Both means it must be defined in both (with the local taking precedence).
      * Service (which service uses this variable)
      * Default/Example Value (if applicable, but do not hardcode secrets)
      * Description (what this variable is for)
   - **Volumes & Networks:** List any volumes or networks defined in the compose file with a brief description of their purpose.
   - **Official Documentation:** Provide a link to the official documentation for the service (if applicable).
5. **Makefile Integration:** Add a new target in the root `Makefile` to allow starting this service with `make up-<name>` and `make down-<name>`.
6. **Environment Variables:** All environment variables should be defined in the root of the service directory in a `.env` file. Do not hardcode sensitive values in the `docker-compose.yml`.
   - **App-Specific `.env`:** Every app folder MUST contain a `.env` and `.env.example` if the compose file requires it.
   - **Strict No-Hardcoding Policy:** Never include actual passwords or keys in `docker-compose.yml`, even as "default" values in the `${VAR:-default}` syntax.
   - **The `.env` / `.env.example` Split:** * **`.env`**: Must be created in the app folder with **working default values** for non-sensitive items (like `DB_NAME` or `DB_USER`) and actual secrets for your local environment.
      * **`.env.example`**: Must be created with **placeholders** (e.g., `PASSWORD=your_password_here`) to serve as a template.
   - **Variable Source Truth:** The `docker-compose.yml` should only reference variables. If a default is needed for a non-sensitive item, define it in the local `.env` file rather than the YAML.

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

## Tech Stack Preferences
- **Logging:** Centralized via Dozzle (`logs.localhost`).
- **Updates:** Managed by What's Up Docker (WUD) (no manual pulls).
- **Environment:** Use `${TZ}` and `${DOMAIN}` variables.
- **Constraints:** Always include log-rotation (max-size: 10m) for every service.