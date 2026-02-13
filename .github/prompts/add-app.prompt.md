---
name: add-app
description: Standardized workflow for adding a new Dockerized service to the Mini-Cloud
---
You are an expert DevSecOps engineer. Your task is to generate a new service block for a Docker Compose file and its associated configuration based on the following strict architecture rules.

# Step 1: Research & Planning
Before generating any files, you MUST perform a web search using `@github #web` to find the following for the app: <app_name>
1. The most popular/official Docker image (e.g., from Docker Hub or Quay).
3. The services that need to be defined in the `docker-compose.yml` (e.g., app, database, cache).
4. The best healthcheck endpoint (e.g., /health, /api/v1/status, or a simple TCP check).
5. Network Binding: Determine if the app defaults to localhost and identify the CLI flag needed to bind it to 0.0.0.0 (e.g., --host 0.0.0.0 or -H 0.0.0.0).

# Step 2: User Confirmation
Present a "Proposal" to the user and WAIT for their approval. Do not generate code yet.
Include:
- **Docker Image:** (e.g., `metabase:latest`)
- **Service Types and Names:** (e.g., `metabase` for the app, `metabase-db` for the database)

# Step 3: Implementation (After Approval)
Once approved, follow the **Standard Docker Compose Pattern** in `copilot-instructions.md`:
1. **Choose a Name:** Pick a unique name for the service (e.g., `myapp`).
2. **Create Directory:** Make a new folder under `/apps` (e.g., `/apps/myapp`).
3. **Write Docker Compose:** Create `apps/<app_name>/docker-compose.yml` with the strict 10-key ordering.
4. **Environment Variables:** Create `apps/<app_name>/.env.example` and `apps/<app_name>/.env`.
5. **README.md:** Create `apps/<app_name>/README.md` with the required sections.
5. **Root Makefile:** Update the root `Makefile` with `up-` and `down-` targets.
6. Always use `traefik.docker.network=home_network` label to prevent 504 errors. If the service is connected to multiple networks, this label is mandatory.

### 1. Mandatory Service Structure
Every service MUST follow this exact key order. Do not skip or reorder:
1. `image` Prefer using latest official images when possible. (postgres:latest, redis:latest, etc.)
2. `container_name` (matches service name)
3. `restart: unless-stopped`
4. `networks`: Always include `home_network`. Add internal network if service-to-service communication is needed.
5. `volumes`: Use named volumes with the prefix `home_<appname>_data`.
6. `labels`: Include Traefik rules (enable, host rule, port, and `traefik.docker.network=home_network`).
7. `environment`: Use `${VAR}` syntax.
8. `logging`: Always set `max-size: "10m"`.
9. `healthcheck`: Must include test, interval, and start_period.
10. `depends_on`: Only if this service depends on another service in the same compose file.
11. `env_file`: Only if you have a separate env file for this service (not required if all variables are in the root `.env`).

### 2. Examples of Correct Output
Follow the pattern of this `glance` service:
```yaml
  glance:
    image: glanceapp/glance:latest
    container_name: glance
    restart: unless-stopped
    networks:
      - home_network
    volumes:
      - ./glance.yml:/app/config/glance.yml:ro
      - home_glance_data:/app/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.glance.rule=Host(`glance.${DOMAIN}`)"
      - "traefik.http.services.glance.loadbalancer.server.port=8080"
      - "traefik.docker.network=home_network"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 1m
      start_period: 30s
```

### 3. Examples of README.md Sections
- Give title
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


### 4. Environment Variables

- All environment variables should be defined in the root of the service directory in a `.env` file. Do not hardcode sensitive values in the `docker-compose.yml`. Do not use the `${VAR:-default}` syntax in the compose file. If a default value is needed for a non-sensitive variable, define it in the local `.env` file instead.
- **Strict No-Hardcoding Policy:** Never include actual passwords or keys in `docker-compose.yml`, even as "default" values in the `${VAR:-default}` syntax.
- **App-Specific `.env`:** Every app folder MUST contain a `.env` and `.env.example` if the compose file requires it.
- **The `.env` / `.env.example` Split:** * **`.env`**: Must be created in the app folder with **working default values** for non-sensitive items (like `DB_NAME` or `DB_USER`) and actual secrets for your local environment.
    * **`.env.example`**: Must be created with **placeholders** (e.g., `PASSWORD=your_password_here`) to serve as a template.
- **Variable Source Truth:** The `docker-compose.yml` should only reference variables. If a default is needed for a non-sensitive item, define it in the local `.env` file rather than the YAML.