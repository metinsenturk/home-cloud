---
title: Docker Healthchecks
description: Understanding Docker container healthchecks, types, methods, and best practices
created: 2026-02-14
updated: 2026-02-14
tags:
  - docker
  - healthcheck
  - monitoring
  - containers
  - devops
category: Docker
references:
  - https://docs.docker.com/engine/reference/builder/#healthcheck
  - https://docs.docker.com/compose/compose-file/#healthcheck
---

# Docker Healthchecks

## Why Healthchecks Are Needed

Docker healthchecks allow you to define custom logic to verify if a container is functioning correctly beyond just checking if the process is running. Without healthchecks, Docker only knows if the main process has crashed—it cannot detect if your application is deadlocked, stuck, or unable to serve requests.

### Key Benefits

1. **Service Availability**: Detect when a service is running but not functioning (e.g., database accepts connections but can't execute queries)
2. **Orchestration Integration**: Tools like Docker Swarm, Kubernetes, and Traefik use health status to route traffic only to healthy containers
3. **Automatic Recovery**: Combined with restart policies, unhealthy containers can be automatically restarted
4. **Monitoring**: Health status is visible in `docker ps` and can be consumed by monitoring tools
5. **Dependency Management**: `depends_on` with `condition: service_healthy` ensures dependent services wait for healthy upstreams

## Healthcheck Types

### 1. CMD (Shell-Free Execution)

Executes the command directly without a shell wrapper. Most efficient for simple binary calls.

```yaml
healthcheck:
  test: ["CMD", "pg_isready", "-U", "postgres"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 30s
```

**When to use:**
- Native binary exists in the container
- No shell features needed (pipes, redirects, variables)
- Performance is critical

### 2. CMD-SHELL (Shell Execution)

Runs the command through `/bin/sh -c`, allowing shell features and scripting.

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**When to use:**
- Need shell features (pipes, logical operators, variables)
- Complex checks requiring multiple commands
- Environment variable substitution

### 3. NONE (Disable Healthcheck)

Disables healthchecks inherited from the base image.

```yaml
healthcheck:
  disable: true
```

**When to use:**
- Override inherited healthcheck from base image
- Container is ephemeral or initialization-only
- External monitoring is preferred

## Healthcheck Methods

### HTTP/HTTPS Checks

Best for web services and APIs with health endpoints.

```yaml
# Using curl
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  
# Using wget
healthcheck:
  test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1"]
```

**Pros:**
- Industry standard for web services
- Can check internal logic through dedicated health endpoints
- Works well with load balancers

**Cons:**
- Requires curl/wget in container (adds image size)
- Network overhead (even for localhost)
- May need to handle HTTPS certificates

### Native Database Tools

Prefer database-specific utilities over generic HTTP checks.

```yaml
# PostgreSQL
healthcheck:
  test: ["CMD", "pg_isready", "-U", "postgres", "-d", "mydb"]
  
# MySQL/MariaDB
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p$$MYSQL_ROOT_PASSWORD"]
  
# MSSQL
healthcheck:
  test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $$SA_PASSWORD -Q 'SELECT 1' -C"]
  
# Redis
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  
# MongoDB
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
```

**Pros:**
- No additional dependencies
- Tests actual database connectivity and readiness
- Lightweight and fast

**Cons:**
- Database-specific (not portable)
- May require authentication credentials

### TCP Socket Checks

Fallback when no native tools or HTTP clients are available. Uses shell built-in `/dev/tcp` pseudo-device (bash/ash only).

```yaml
healthcheck:
  test: ["CMD-SHELL", "exec 3<>/dev/tcp/127.0.0.1/8080 && echo -e 'GET / HTTP/1.1\\r\\n\\r\\n' >&3 && cat <&3 | grep -q 'HTTP' || exit 1"]
  
# Simple port check (just verify port is listening)
healthcheck:
  test: ["CMD-SHELL", "timeout 1 bash -c 'cat < /dev/null > /dev/tcp/localhost/8080' || exit 1"]
```

**Pros:**
- No external dependencies
- Works in minimal images
- Tests port availability

**Cons:**
- Requires bash/ash shell
- Only verifies port is listening, not application logic
- Less readable and maintainable

### Process Checks

Verify specific processes are running.

```yaml
healthcheck:
  test: ["CMD-SHELL", "pgrep -f 'my-app-process' || exit 1"]
```

**Pros:**
- Simple and fast
- No network overhead

**Cons:**
- Process running ≠ application healthy
- Doesn't test actual functionality

### File-Based Checks

Check for existence of files or content.

```yaml
healthcheck:
  test: ["CMD-SHELL", "test -f /app/ready || exit 1"]
```

**When to use:**
- Application writes readiness markers
- Used during initialization phases
- Coordinating with init scripts

## Configuration Parameters

### interval
Default: `30s`

Time between health checks. Shorter intervals mean faster failure detection but more CPU/IO overhead.

```yaml
interval: 10s  # More responsive
interval: 60s  # Less overhead
```

### timeout
Default: `30s`

Maximum time to wait for a single check to complete.

```yaml
timeout: 5s   # Fast-failing services
timeout: 30s  # Slow-responding databases
```

### retries
Default: `3`

Number of consecutive failures before marking container unhealthy.

```yaml
retries: 3   # Standard (requires 3 failures)
retries: 1   # Strict (immediate fail)
retries: 5   # Tolerant (allow temporary issues)
```

### start_period
Default: `0s`

Grace period during container initialization where failed checks don't count toward retries. Critical for databases and applications with long startup times.

```yaml
start_period: 30s   # Web applications
start_period: 60s   # Databases with initialization
start_period: 120s  # Complex apps with migrations
```

**Important:** Failures during `start_period` still appear in status but don't count toward the `retries` limit.

## Best Practices

### 1. Choose the Right Method Hierarchy

Follow this priority order:

1. **Native tools** (pg_isready, redis-cli, mysqladmin) ← Preferred
2. **HTTP health endpoints** (if your app provides one)
3. **TCP socket checks** (when no other option)
4. **Process checks** (last resort)

### 2. Always Include start_period

Databases and applications need time to initialize. Without `start_period`, they may be marked unhealthy during startup.

```yaml
# ❌ Bad - No grace period
healthcheck:
  test: ["CMD", "pg_isready"]
  retries: 3

# ✅ Good - Grace period for initialization
healthcheck:
  test: ["CMD", "pg_isready"]
  retries: 3
  start_period: 60s
```

### 3. Design Health Endpoints Thoughtfully

Don't just return HTTP 200; actually test critical dependencies.

```python
# ❌ Bad - Only checks if HTTP server responds
@app.route('/health')
def health():
    return 'OK', 200

# ✅ Good - Verifies database connectivity
@app.route('/health')
def health():
    try:
        db.execute('SELECT 1')
        return 'OK', 200
    except Exception:
        return 'Unhealthy', 503
```

### 4. Avoid Environment Variable Pitfalls

Use `$$VAR` in Compose files to pass variables to the container (not just `$VAR` which expands at compose-time).

```yaml
# ❌ Wrong - Expands on host during compose up
test: ["CMD-SHELL", "mysql -p$MYSQL_PASSWORD"]

# ✅ Correct - Escapes $ so it expands in container
test: ["CMD-SHELL", "mysql -p$$MYSQL_PASSWORD"]
```

### 5. Match Healthcheck to Service Criticality

```yaml
# Critical service - Strict checking
healthcheck:
  interval: 10s
  timeout: 5s
  retries: 2
  start_period: 30s

# Background worker - Lenient checking
healthcheck:
  interval: 60s
  timeout: 10s
  retries: 5
  start_period: 120s
```

### 6. Bind to 0.0.0.0, Not 127.0.0.1

If your service listens on `127.0.0.1` inside the container, external network checks (from reverse proxies) will fail.

```yaml
# ❌ Service binds to 127.0.0.1 - Only container-local checks work
command: ["uvicorn", "main:app", "--host", "127.0.0.1"]

# ✅ Service binds to 0.0.0.0 - Accessible from Docker networks
command: ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

## Complete Examples

### Web Application (FastAPI)

```yaml
services:
  api:
    image: myapp:latest
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 40s
```

### PostgreSQL Database

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: admin
      POSTGRES_DB: appdb
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "admin", "-d", "appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s
```

### Redis Cache

```yaml
services:
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 10s
```

### MSSQL Server

```yaml
services:
  mssql:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      SA_PASSWORD: SecurePassword123!
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $$SA_PASSWORD -Q 'SELECT 1' -C"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 90s
```

### Minimal Container (No curl/wget)

```yaml
services:
  minimal:
    image: alpine:latest
    command: ["web-server", "--port", "8080"]
    healthcheck:
      test: ["CMD-SHELL", "exec 3<>/dev/tcp/127.0.0.1/8080 || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
```

## Checking Health Status

### Via Docker CLI

```bash
# View health status
docker ps

# Inspect health check details
docker inspect --format='{{json .State.Health}}' container-name | jq

# View health check logs
docker inspect container-name | jq '.[0].State.Health.Log'
```

### In Docker Compose

```bash
# Check service health
docker compose ps

# Dependent service waits for health
services:
  web:
    depends_on:
      db:
        condition: service_healthy
  
  db:
    healthcheck:
      test: ["CMD", "pg_isready"]
```

## Common Pitfalls

### 1. Healthcheck Too Strict
If `interval` is too short or `retries` too low, temporary issues mark containers unhealthy unnecessarily.

### 2. No start_period
Databases and apps with migrations fail healthchecks during initialization, causing endless restart loops.

### 3. Ignoring Exit Codes
Healthcheck commands must explicitly `exit 1` on failure. Many tools return 0 even on errors.

```bash
# ❌ Bad - curl returns 0 even on 404/500
curl http://localhost:8080/health

# ✅ Good - curl -f exits 22 on HTTP errors
curl -f http://localhost:8080/health || exit 1
```

### 4. Testing Wrong Layer
Checking process existence doesn't verify application functionality. Always test the actual service capability.

## Integration with Orchestration

### Docker Swarm
Uses healthchecks for rolling updates and load balancing.

### Kubernetes
Healthchecks in Docker are **not** used by Kubernetes; use `livenessProbe` and `readinessProbe` instead.

### Traefik
Respects container health status and avoids routing to unhealthy backends when configured properly.

## Conclusion

Docker healthchecks are essential for production deployments. Prioritize native tools, include proper `start_period` grace periods, and verify actual application functionality rather than just process existence. Well-configured healthchecks enable robust self-healing systems and reliable service orchestration.
