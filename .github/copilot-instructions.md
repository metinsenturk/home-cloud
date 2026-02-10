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
3. **Labels:** - `traefik.enable=true`
   - `traefik.http.routers.<name>.rule=Host('<name>.localhost')`
   - `traefik.http.services.<name>.loadbalancer.server.port=<port>`
4. Avoid using version key in `docker-compose.yml` (use the latest syntax).
5. Avoid hardcoding ports in the compose file; rely on Traefik for routing.
6. Always set the keys in the same order for consistency unser services: image, container_name, restart, command, ports, networks, volumes, labels, environment, logging, healthcheck, depends_on.

## Makefile Integration
- New services should be added as variables at the top of the root `Makefile`.
- Add a specific `up-<name>` target and include it in the `up-all` target.

## Tech Stack Preferences
- **Logging:** Centralized via Dozzle (`logs.localhost`).
- **Updates:** Managed by Watchtower (no manual pulls).
- **Environment:** Use `${TZ}` and `${DOMAIN}` variables.
- **Constraints:** Always include log-rotation (max-size: 10m) for every service.