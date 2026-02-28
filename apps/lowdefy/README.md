# Lowdefy

Lowdefy is an open-source low-code framework for building internal tools, admin panels, dashboards, and workflows. It uses YAML configuration to define applications without writing code, while still allowing custom JavaScript for complex logic.

## Services

- **lowdefy**: Main application server that builds and serves the app from YAML configuration

## Access

- **Web Interface**: [http://lowdefy.localhost](http://lowdefy.localhost)

## Starting this App

### From the app folder:
```bash
cd apps/lowdefy
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-lowdefy
```

## Configuration

### Initial Setup

1. **Copy environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Customize your app** (optional):
   - Edit `config/lowdefy.yaml` to define your application structure
   - Add pages, components, connections, and authentication
   - The starter configuration includes a welcome page

3. **Build and start the service**:
   ```bash
   make up-lowdefy
   ```
   Note: The first start will take longer as it builds the Docker image (compiles YAML to Next.js app)

4. **Access the app**: Navigate to `http://lowdefy.localhost` in your browser

### Updating Your App

**Important**: Lowdefy v4 uses a build-time compilation approach. Configuration changes require rebuilding the Docker image.

After editing `config/lowdefy.yaml`:
```bash
make down-lowdefy
docker compose --env-file .env --env-file apps/lowdefy/.env -f apps/lowdefy/docker-compose.yml build --no-cache
make up-lowdefy
```

Or from the app folder:
```bash
docker compose --env-file ../../.env --env-file .env build --no-cache
docker compose --env-file ../../.env --env-file .env up -d
```

### Development Workflow

For faster iteration during development, consider running Lowdefy locally without Docker:
```bash
cd config
npx lowdefy@4 dev --port 3000
```
This provides hot-reload and faster feedback loops. Once satisfied, rebuild the Docker image for production deployment.

### Connecting to Infrastructure Services

To connect Lowdefy to infrastructure databases in this home-cloud setup:

**PostgreSQL Example:**
```yaml
connections:
  - id: postgres_connection
    type: PostgresSQL
    properties:
      host: infra-postgres
      port: 5432
      database: your_db_name
      username: postgres
      password: ${INFRA_POSTGRES_PASSWORD}
```

**MongoDB Example:**
```yaml
connections:
  - id: mongo_connection
    type: MongoDB
    properties:
      connectionUri: mongodb://infra-mongodb:27017/your_db_name
```

**Redis Example:**
```yaml
connections:
  - id: redis_connection
    type: Redis
    properties:
      host: infra-redis
      port: 6379
      password: ${INFRA_REDIS_PASSWORD}
```

### Authentication Setup

Lowdefy supports various authentication providers. Example with Auth0:

```yaml
auth:
  pages:
    public:
      - welcome
    protected:
      - admin_page
  providers:
    - id: auth0
      type: Auth0
      properties:
        domain: your-tenant.auth0.com
        clientId: ${AUTH0_CLIENT_ID}
        clientSecret: ${AUTH0_CLIENT_SECRET}
```

## Environment Variables

| Variable Name | Source | Service | Default/Example | Description |
|--------------|--------|---------|-----------------|-------------|
| `TZ` | Global | lowdefy | `America/New_York` | Timezone for the container |
| `DOMAIN` | Global | lowdefy | `localhost` | Domain for Traefik routing |

**Note**: `NODE_ENV` and `PORT` are hardcoded in the Dockerfile (production and 3000 respectively).

### Optional Variables for Advanced Configuration

If using authentication or external connections, add to `.env`:
```bash
# Auth0 (example)
AUTH0_CLIENT_ID=your_client_id
AUTH0_CLIENT_SECRET=your_client_secret

# Database passwords (reference infrastructure secrets)
INFRA_POSTGRES_PASSWORD=${INFRA_POSTGRES_PASSWORD}
INFRA_REDIS_PASSWORD=${INFRA_REDIS_PASSWORD}
```

## Volumes & Networks

### Volumes
- No persistent volumes required - the application is built into the Docker image

### Networks
- `home_network`: External network for Traefik reverse proxy access

## Development Workflow

1. **Edit Configuration**: Modify `config/lowdefy.yaml`
2. **Restart Container**: `make down-lowdefy && make up-lowdefy`
3. **View Changes**: Refresh browser at `http://lowdefy.localhost`
4. **Check Logs**: `docker logs lowdefy -f`

## Use Cases

- **Admin Panels**: Build CRUD interfaces for your databases
- **Internal Tools**: Create forms, reports, and workflow tools
- **Dashboards**: Visualize data with charts and tables
- **Data Entry**: Build forms with validation and business logic
- **Automation Workflows**: Trigger actions based on events or schedules

## Troubleshooting

### Build Errors on Startup

If the container fails to start with YAML parsing errors:
```bash
docker logs lowdefy
```
Check `config/lowdefy.yaml` for syntax errors (indentation, colons, etc.).

### Changes Not Appearing

Lowdefy builds the app on container startup. After editing `lowdefy.yaml`:
```bash
docker restart lowdefy
```

### Connection Issues to Databases

Ensure:
- Infrastructure services are running (`docker ps | grep infra-`)
- Service names match (e.g., `infra-postgres`, not `postgres`)
- Passwords are correctly referenced from environment variables
- Lowdefy container is on the correct networks

### 502 Bad Gateway

If you get a 502 error:
1. Check if container is running: `docker ps | grep lowdefy`
2. Check logs: `docker logs lowdefy`
3. Verify healthcheck: `docker inspect lowdefy | grep -A 10 Health`

## Official Documentation

- **Lowdefy Docs**: https://docs.lowdefy.com
- **GitHub**: https://github.com/lowdefy/lowdefy
- **Docker Hub**: https://hub.docker.com/r/lowdefy/lowdefy
- **Examples**: https://github.com/lowdefy/lowdefy-example-gallery
- **Community**: https://github.com/lowdefy/lowdefy/discussions
