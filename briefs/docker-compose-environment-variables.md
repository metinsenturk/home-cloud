---
title: Docker Compose Environment Variables
description: Comprehensive guide to defining environment variables in Docker Compose files, including the environment key, env_file key, .env file behavior, and precedence rules
created: 2026-02-15
updated: 2026-02-15
tags:
  - docker-compose
  - environment-variables
  - configuration
  - docker
category: Docker
references:
  - https://docs.docker.com/compose/environment-variables/
  - https://docs.docker.com/compose/compose-file/
---

# Docker Compose Environment Variables

Docker Compose provides multiple ways to pass environment variables to containers. Understanding the different methods and their precedence is crucial for proper configuration management.

## Methods to Define Environment Variables

### 1. The `environment` Key

Define variables directly in the `docker-compose.yml` file using the `environment` key. This is the most explicit and readable method.

**Syntax:**
```yaml
services:
  myapp:
    environment:
      - VAR_NAME=value
      - ANOTHER_VAR=another_value
      - DATABASE_URL=postgres://localhost/mydb
```

**Alternative Syntax (Long Form):**
```yaml
services:
  myapp:
    environment:
      VAR_NAME: value
      ANOTHER_VAR: another_value
      DATABASE_URL: postgres://localhost/mydb
```

**Key Points:**
- Values defined here are **hardcoded** in the compose file
- Good for static, non-sensitive configuration
- Supports variable interpolation from compose context (see below)
- Overrides values from `.env` files

### 2. The `env_file` Key

Reference external environment files to load variables into a container. Useful for separating configuration from the compose definition.

**Syntax:**
```yaml
services:
  myapp:
    env_file:
      - .env
      - app.env
```

**Key Points:**
- Path is relative to the compose file location
- Files are processed in order
- Format: `KEY=VALUE` (one per line)
- Comments and blank lines are supported
- Variables defined later in the list override earlier ones
- NOT interpolated by Docker Compose (shell variables are not expanded)

**Example `.env` File:**
```
DATABASE_PASSWORD=secret123
API_KEY=abc123xyz
DEBUG=false
```

### 3. Default `.env` File Behavior

Docker Compose automatically loads variables from a `.env` file in the compose file's directory, **if it exists**.

**Key Characteristics:**
- The default `.env` file is automatically loaded without explicit declaration
- Only the file named exactly `.env` is loaded by default
- Applied **before** explicit `env_file` declarations
- Used for variable substitution within the compose file itself
- Environment variables are accessible during compose file parsing

**Important:** The `.env` file is primarily used for:
1. **Compose file interpolation** — Variables referenced in the compose file (e.g., `${DB_HOST}`)
2. **Default environment for services** — Variables not explicitly overridden by `environment:` or `env_file:`

## Variable Interpolation in Compose Files

The `.env` file enables dynamic composition. Variables referenced in the compose file are substituted at parse time.

```yaml
services:
  myapp:
    image: myimage:${IMAGE_TAG}
    environment:
      - DATABASE_HOST=${DB_HOST}
      - DATABASE_PORT=${DB_PORT:-5432}  # Default value if not defined
```

### Interpolation Rules:
- **${}** syntax: `${VARIABLE_NAME}`
- **Default values:** `${VARIABLE_NAME:-default_value}`
- **Empty string fallback:** `${VARIABLE_NAME:?error message}` (fails if not set)
- Only applied during compose file parsing, not inside containers

## Environment Variable Precedence

When multiple sources define the same variable, Docker Compose applies precedence in this order (highest to lowest):

1. **Compose CLI flags** (e.g., `docker compose --env-file custom.env`)
2. **Environment key in compose file** (explicitly set variables)
3. **Host environment variables** (inherited from the shell running `docker compose`)
4. **env_file declarations** (in order; later files override earlier ones)
5. **Default .env file** (automatically loaded `.env`)
6. **Docker defaults** (if nothing else is set)

### Practical Example:

Given:
```bash
# Host shell
export VAR=host_value

# Root .env
VAR=default_value
ANOTHER=default_another

# apps/myapp/.env
VAR=app_value
APP_SPECIFIC=app_only
```

And this `docker-compose.yml`:
```yaml
services:
  myapp:
    environment:
      - VAR=compose_explicit
      - FROM_ENV=from_env
```

**Result in container:**
- `VAR=compose_explicit` (compose file `environment:` wins)
- `ANOTHER=default_another` (from automatic `.env`)
- `APP_SPECIFIC=app_only` (from `env_file:` declaration)
- `FROM_ENV=from_env` (from compose file)
- Host `VAR=host_value` is NOT used (overridden by all above)

## Double-Env Pattern (Advanced)

For modular applications, load variables in layers to allow overrides:

```bash
docker compose \
  --env-file .env \
  --env-file apps/myapp/.env \
  -f apps/myapp/docker-compose.yml up -d
```

**Behavior:**
- `.env` is loaded first (global defaults)
- `apps/myapp/.env` is loaded second (app-specific overrides)
- Variables in the second file override the first
- `environment:` key in compose still has highest priority

## Sensitive Variables (Secrets vs Environment)

### Environment Variables (for non-secrets):
```yaml
services:
  myapp:
    environment:
      - LOG_LEVEL=debug
      - API_TIMEOUT=30
```

### Docker Secrets (for sensitive data):
```yaml
services:
  myapp:
    secrets:
      - db_password
    environment:
      - DATABASE_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Note:** Secrets are only available in Swarm mode. For standalone compose, `.env` files with restricted permissions (e.g., `chmod 600`) are the standard approach.

## Best Practices

1. **Use `.env` for defaults:** Store common configuration in a root `.env` file
2. **Use `app.env` for overrides:** Keep app-specific settings in `apps/<name>/.env`
3. **Explicit is better than implicit:** Use `environment:` for crucial values that should be visible in the compose file
4. **Never commit secrets:** Add `.env` and app `.env` files to `.gitignore`
5. **Document defaults:** Include `.env.example` with all keys and example values
6. **Avoid shell expansion in `env_file`:** Variables in `.env` files are NOT shell-expanded
7. **Use interpolation for paths:** Reference `.env` variables in the compose file for dynamic paths and tags

## Common Pitfalls

| Pitfall | Issue | Solution |
|---------|-------|----------|
| Variables in `env_file` not expanding | `.env` files don't support `$SHELL_VAR` | Use literal values or interpolate in compose file before passing to `env_file` |
| Container doesn't see variables | `env_file` path is relative to compose, not shell | Use relative paths from the compose file location |
| Variables override each other | Unclear precedence order | Remember: compose `environment:` key > cli flags > host env |
| `.env` file not loaded | File must be named exactly `.env` | Use `--env-file` flag if using a different name |
| Secrets visible in logs | Secrets passed as environment variables | Use Docker Secrets or mount files with restricted permissions |

## Summary Table

| Method | Scope | Interpolated | Use Case |
|--------|-------|--------------|----------|
| `environment:` key | Container | During compose parse | Static, important config |
| `env_file:` | Container | During compose parse (file contents, not shell) | Separate config files |
| `.env` (automatic) | Compose parse + Container | Yes | Global defaults |
| CLI `--env-file` | Compose parse + Container | Yes | Runtime overrides |
| Host environment | Compose parse | Yes (if referenced) | Build-time values |
