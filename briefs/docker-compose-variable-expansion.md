---
title: Shell Variable Expansion in Docker Compose ($, $$)
description: Understanding $ and $$ for environment variable expansion and escaping in Docker Compose files
created: 2026-02-14
updated: 2026-02-14
tags:
  - docker-compose
  - environment-variables
  - shell-expansion
  - escaping
category: Docker
references:
  - https://docs.docker.com/compose/environment-variables/
  - https://docs.docker.com/compose/compose-file/05-services/#environment
---

# Shell Variable Expansion in Docker Compose

## Overview

Docker Compose supports variable expansion in `docker-compose.yml` files using shell-style syntax. Understanding the difference between `$` and `$$` is crucial for correctly passing environment variables to containers and avoiding unexpected behavior.

## What Are `$` and `$$`?

### `$VARIABLE` - Single Dollar Sign
A single dollar sign is used for **variable expansion**. Docker Compose interprets `$VARIABLE` and replaces it with the value from:
1. Environment variables (from `.env` file or system environment)
2. Variables defined in the Compose file itself

**Example:**
```yaml
environment:
  DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@localhost/mydb
```

If `.env` contains `DB_USER=admin`, then `${DB_USER}` is replaced with `admin`.

### `$$VARIABLE` - Double Dollar Sign
A double dollar sign is used for **escaping**. Docker Compose treats `$$` as a literal `$`, which means:
- The variable is NOT expanded by Docker Compose
- Instead, it passes a single `$` to the container
- This allows the container's shell or application to perform the variable expansion

**Example:**
```yaml
environment:
  POSTGRES_INITDB_ARGS: -c statement_timeout=$$db_statement_timeout
```

This passes `-c statement_timeout=$db_statement_timeout` to PostgreSQL, allowing PostgreSQL itself to interpret `$db_statement_timeout`.

## Use Cases & Why It's Needed

### Use Case 1: Pass Variables to Container Shell Scripts
When a container runs a shell script that expects environment variables, you need to escape the `$` so the script receives the literal variable name.

```yaml
services:
  myapp:
    image: ubuntu
    environment:
      # This will NOT be expanded by Docker Compose
      # Instead, the container receives: MY_VAR=$USER_NAME
      MY_VAR: $$USER_NAME
    command: /bin/bash -c 'echo $MY_VAR'
```

Without `$$`, Docker Compose would try to expand `$USER_NAME` from the host's environment, which might not exist or have an unexpected value.

### Use Case 2: PostgreSQL Connection Strings with Variables
PostgreSQL connection parameters sometimes use `$` syntax. To pass these correctly:

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      # Double $$ ensures PostgreSQL receives the literal $
      POSTGRES_INITDB_ARGS: -c log_statement=$$all
```

### Use Case 3: Prevent Host Environment Pollution
If you want to define variables that should be consumed by the container (not by Docker Compose itself):

```yaml
services:
  app:
    image: myapp
    environment:
      # Expand from .env (Docker Compose interpretation)
      APP_NAME: ${APP_NAME}
      
      # Escape for container's shell (literal $)
      PATH_PREFIX: $$HOME/config
      
      # Container receives: PATH_PREFIX=$HOME/config
      # The container's shell will expand $HOME, not Docker Compose
```

### Use Case 4: Database Initialization Scripts
Many database containers use environment variables for initialization. Escaping ensures the database service receives the variable:

```yaml
services:
  mssql:
    image: mcr.microsoft.com/mssql/server
    environment:
      # MSSQL and backend services use this; don't expand at compose time
      SA_PASSWORD: $$SA_PASSWORD_VALUE
```

## Comparison Table

| Syntax | Behavior | Example |
|--------|----------|---------|
| `$VAR` or `${VAR}` | Expanded by Docker Compose at compose-up time | `.env` value is substituted |
| `$$VAR` or `$${VAR}` | Literal `$` passed to container | Container's shell/app performs expansion |

## Practical Example

```yaml
# .env file
DB_USER=admin
DB_PASSWORD=secret123
APP_HOME=/app

services:
  myapp:
    image: myapp:latest
    environment:
      # Expanded by Docker Compose (from .env)
      DATABASE_USER: ${DB_USER}
      DATABASE_PASSWORD: ${DB_PASSWORD}
      
      # Escaped for container's shell
      HOME_DIR: $$APP_HOME
      WORK_DIR: $$HOME/workspace
      
      # Mix of both
      LOG_FILE: ${APP_HOME}/logs/app.log
      TEMP_DIR: $$TMPDIR/$$APP_NAME
```

**Resulting container environment:**
```bash
DATABASE_USER=admin
DATABASE_PASSWORD=secret123
HOME_DIR=$APP_HOME                          # Literal: container expands
WORK_DIR=$HOME/workspace                    # Literal: container expands
LOG_FILE=/app/logs/app.log                  # Expanded: Docker Compose substituted
TEMP_DIR=$TMPDIR/$APP_NAME                  # Literal: container expands
```

## Best Practices

1. **Use `$` when:** You want Docker Compose to substitute values from `.env` or system environment at compose-up time.
2. **Use `$$` when:** The container's shell, application, or service needs to receive and interpret the variable.
3. **Be explicit:** Use `${VAR}` instead of `$VAR` for clarity and to avoid accidental word concatenation.
4. **Document why:** Always add comments in `docker-compose.yml` explaining whether escaping is used and why.
5. **Test:** Run `docker compose config` to see the actual expanded values before deploying.

## Debugging

To see how Docker Compose expands variables:

```bash
# Display the resolved docker-compose.yml
docker compose config

# This shows the exact values that will be used
```

## Summary

- **`$` (single):** Docker Compose expands the variable using values from `.env` or system environment.
- **`$$` (double):** Docker Compose passes a literal `$` to the container, allowing the container's shell/application to expand it.
- **When to use each:** Depends on whether you want Docker Compose or the container to interpret the variable.
