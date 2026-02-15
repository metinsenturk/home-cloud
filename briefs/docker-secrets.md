---
title: Docker Secrets Management
description: Understanding Docker secrets, how they work, best practices, and comparison with alternatives like environment files and volume mounts
created: 2026-02-14
updated: 2026-02-14
tags:
  - docker
  - security
  - secrets-management
  - environment-variables
  - best-practices
category: Docker
references:
  - https://docs.docker.com/engine/swarm/secrets/
  - https://docs.docker.com/compose/use-secrets/
  - https://docs.docker.com/engine/reference/commandline/secret_create/
---

# Docker Secrets Management

## Overview

Docker secrets is a secure mechanism for managing sensitive data (passwords, API keys, certificates, database credentials, etc.) in Docker applications. Secrets are encrypted at rest and transmitted securely to containers that need them, providing better security than environment variables or plain text files.

## What Are Docker Secrets?

Docker secrets are:
- **Encrypted at rest** in the Docker daemon's database
- **Transmitted securely** to containers over a mutual TLS connection
- **Available only to authorized services** in Swarm mode
- **Mounted as read-only files** inside containers at `/run/secrets/<secret_name>`
- **Automatically removed** when the container/service terminates

### How Secrets Work

1. **Create a secret** using `docker secret create` or Docker Compose
2. **Grant access** to specific services via `secrets:` declaration
3. **Access inside container** by reading files from `/run/secrets/`

**Example:**
```bash
# Create a secret
echo "my_secure_password" | docker secret create db_password -

# Grant to service via Docker Compose
services:
  db:
    image: postgres
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

Inside the container:
```bash
cat /run/secrets/db_password  # Output: my_secure_password
```

## Comparison: Docker Secrets vs. Alternatives

### 1. Environment Variables (`.env` files)

**Characteristics:**
- Plain text in `.env` file or passed via `-e` flag
- Visible in `docker ps` and `docker inspect` output
- Exposed in process listings (`ps aux`)
- Easy to accidentally commit to version control
- Simple to use

**Pros:**
- Simple and straightforward
- No special Docker setup required
- Works with Docker Compose easily

**Cons:**
- **Not secure** for sensitive data
- Visible in multiple places (process memory, logs, inspect output)
- Risk of accidental exposure in version control
- No access control

**Use for:** Non-sensitive configuration (app versions, feature flags, timeouts)

```yaml
# Not recommended for secrets
services:
  app:
    environment:
      DATABASE_PASSWORD: mypassword123  # SECURITY RISK!
```

### 2. Volume Mounts (Bind Mounts or Named Volumes)

**Characteristics:**
- Files mounted from host or volume into container
- Full read/write access by default
- Visible in container filesystem
- Permission-based access control

**Pros:**
- Good for config files
- Can be shared across services
- File-based permissions provide some control

**Cons:**
- Not encrypted at rest without additional tools
- Requires managing file permissions manually
- Visible to anyone with filesystem access
- No Docker-native access control

**Use for:** Configuration files, certificates with proper file permissions

```yaml
services:
  app:
    volumes:
      - /secure/path/secrets.conf:/app/config/secrets.conf:ro
```

### 3. Docker Secrets (Swarm/Compose)

**Characteristics:**
- Encrypted in Docker daemon's database
- Read-only files in `/run/secrets/`
- Access control per service
- Supported in Docker Compose (v3.1+)
- Automatic cleanup

**Pros:**
- **Encrypted at rest** in the daemon
- **Access control** - only granted services can read
- **Automatic cleanup** when service terminates
- **Not visible** in `docker ps`, `docker inspect`, or logs
- Docker-native solution
- No manual file permission management

**Cons:**
- Requires Docker Compose v3.1+ or Docker Swarm
- Secrets are files, not environment variables (requires application changes)
- Requires reading from `/run/secrets/` within container
- Not suitable for non-Docker environments

**Use for:** Sensitive data (passwords, API keys, tokens, certificates)

```yaml
services:
  db:
    image: postgres
    secrets:
      - db_password
      - db_root_cert
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

### 4. HashiCorp Vault / External Secrets Manager

**Characteristics:**
- Centralized secret management
- Dynamic secret generation
- Audit logging
- Encryption and key rotation

**Pros:**
- Most secure for enterprise
- Centralized management across multiple environments
- Dynamic secrets and rotation
- Comprehensive audit trails
- Supports secret versioning

**Cons:**
- Complex setup and maintenance
- Additional infrastructure required
- Learning curve
- Overkill for small projects

**Use for:** Enterprise environments, secrets rotation, multi-environment setups

```yaml
# Requires a sidecar or init container to fetch from Vault
services:
  app:
    image: myapp
    environment:
      VAULT_ADDR: https://vault.example.com
      VAULT_TOKEN_FILE: /run/secrets/vault_token
```

### 5. Pass Secrets via Build Arguments

**Characteristics:**
- Secrets during image build process
- Can be cached in image layers
- Not available at runtime

**Pros:**
- Good for build-time secrets (npm tokens, build credentials)
- Docker-native

**Cons:**
- **Visible in image layers** if not done carefully
- Not suitable for runtime secrets
- Can be accidentally committed to registries

**Use for:** Build-time credentials only (with `--secret` flag in Docker 18.09+)

```dockerfile
# Use BuildKit secrets (Docker 18.09+)
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install
```

## Comparison Table

| Method | Encrypted at Rest | Access Control | Visible in docker inspect | Visible in Logs | Best For |
|--------|------------------|-----------------|-------------------------|-----------------|----------|
| **Environment Variables** | ❌ No | ❌ No | ✅ Yes | ⚠️ Often | Non-sensitive config |
| **Volume Mounts** | ❌ No* | ✅ File-based | ❌ No | ❌ No | Config files |
| **Docker Secrets** | ✅ Yes | ✅ Per-service | ❌ No | ❌ No | Passwords, API keys |
| **External Vault** | ✅ Yes | ✅ Advanced | ❌ No | ⚠️ Configurable | Enterprise secrets |
| **Build Arguments** | ⚠️ Buildkit | ❌ No | ❌ No (Modern) | ❌ No | Build-time only |

*With filesystem encryption only

## When to Use Each

```
Choosing the right secrets management strategy:

┌─────────────────────────────────────────┐
│ Is it sensitive? (password, key, token) │
└──────────┬──────────────────────────────┘
           │
        ┌──┴──┐
        │     │
       Yes   No → Use Environment Variables (.env)
        │
        ├─ Docker Swarm/Compose? → Use Docker Secrets
        │
        ├─ Enterprise/Multi-env? → Use External Vault
        │
        └─ Need highest security? → Use encrypted volume + Vault
```

## Practical Example

```yaml
# docker-compose.yml
version: '3.9'

services:
  postgres:
    image: postgres:15
    environment:
      # Non-sensitive config → environment variable
      POSTGRES_USER: admin
      TZ: UTC
      
      # Sensitive data → secrets
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      
    secrets:
      - db_password
      - ssl_cert

  api:
    image: myapi:latest
    environment:
      # Non-sensitive config → environment variable
      LOG_LEVEL: info
      DATABASE_HOST: postgres
      
      # Reference secret for connection
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
      
      # API key → secret
      EXTERNAL_API_KEY_FILE: /run/secrets/api_key
      
    secrets:
      - db_password
      - api_key
    depends_on:
      - postgres

# Define secrets from external files or stdin
secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
  ssl_cert:
    file: ./secrets/cert.pem
```

**Inside the `api` container:**
```bash
# Read secrets
cat /run/secrets/db_password       # Secure, encrypted
cat /run/secrets/api_key           # Secure, encrypted

# Secrets are automatically cleaned up when container stops
```

## Best Practices

1. **Use Docker Secrets for sensitive data** in production Docker/Swarm environments
2. **Never log secrets** - use `*_FILE` environment variables to point to secret files
3. **Mark secrets as read-only** - mounted at `/run/secrets/` with read-only access by default
4. **Separate secrets from config** - secrets ≠ environment variables
5. **Use external tools for enterprise** - Vault, HashiCorp, AWS Secrets Manager for multi-environment setups
6. **Rotate secrets regularly** - establish a rotation policy
7. **Limit secret access** - only grant secrets to services that need them
8. **Audit secret access** - log which services access which secrets
9. **Never commit secret files** - add `secrets/` to `.gitignore`
10. **Use build-time secrets safely** - use `--mount=type=secret` with BuildKit to avoid leaking in layers

## Common Pitfalls

❌ **Wrong:** Passing secrets via environment variables
```yaml
environment:
  DATABASE_PASSWORD: secretpassword123  # Visible everywhere!
```

✅ **Correct:** Using secrets with `_FILE` suffix
```yaml
environment:
  POSTGRES_PASSWORD_FILE: /run/secrets/db_password
secrets:
  - db_password
```

❌ **Wrong:** Storing secrets in version control
```bash
echo "my_password" >> .env
git add .env  # DO NOT DO THIS!
```

✅ **Correct:** Keep secrets out of version control
```bash
echo secrets/ >> .gitignore
```

## Summary

| Scenario | Solution |
|----------|----------|
| Non-sensitive config (log levels, ports) | Environment variables |
| Configuration files | Volume mounts with proper permissions |
| Passwords, API keys, tokens (Docker) | Docker Secrets |
| Enterprise infrastructure | External Vault or Secrets Manager |
| Build-time credentials | Docker BuildKit `--mount=type=secret` |

**Golden Rule:** If it's sensitive, don't use environment variables. Use Docker Secrets (for containerized apps) or a dedicated secrets manager (for enterprise).
