# Blinko

Blinko is an AI-powered card-based note-taking application designed for quickly capturing and organizing fleeting thoughts and ideas. It features seamless AI assistance, multi-level tagging, full-text search with AI-powered recommendations, markdown export capabilities, and multi-user support with role-based access control.

## Services

- **blinko**: Main web application (Next.js + React + Express)
- **blinko-db**: Dedicated PostgreSQL 16 database

## Access

- **URL**: `http://blinko.${DOMAIN}` (via Traefik)
- **Protocol**: HTTP (or HTTPS if Traefik is configured with SSL)

## Starting this App

### From the app folder:
```bash
cd apps/blinko
docker compose --env-file ../../.env --env-file .env up -d
```

### From the root folder:
```bash
make up-blinko
```

## Configuration

1. **Environment Variables**: Copy `.env.example` to `.env` and configure:
   - `BLINKO_DB_NAME`: PostgreSQL database name (default: `blinko`)
   - `BLINKO_DB_USER`: PostgreSQL database user (default: `postgres`)
   - `BLINKO_DB_PASSWORD`: Secure password for PostgreSQL database
   - `BLINKO_NEXTAUTH_SECRET`: Generate using `openssl rand -hex 32` (64 characters recommended)
   - `BLINKO_OPENAI_API_KEY`: (Optional) OpenAI API key for GPT models
   - `BLINKO_GEMINI_API_KEY`: (Optional) Google Gemini API key
   - `BLINKO_OPENROUTER_API_KEY`: (Optional) OpenRouter API key for multi-model access

2. **First-Time Setup**: 
   - After starting the containers, navigate to `http://blinko.${DOMAIN}`
   - Complete initial setup and create your admin account
   - Configure AI integration (optional) using OpenAI or other providers

3. **AI Integration** (Optional):
   - Blinko supports OpenAI, Ollama, and custom AI providers
   - Configure via the app's settings interface after login

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `BLINKO_DB_NAME` | Local | blinko-db, blinko | blinko | PostgreSQL database name |
| `BLINKO_DB_USER` | Local | blinko-db, blinko | postgres | PostgreSQL database user |
| `BLINKO_DB_PASSWORD` | Local | blinko-db, blinko | N/A | PostgreSQL database password |
| `BLINKO_NEXTAUTH_SECRET` | Local | blinko | N/A | NextAuth.js secret for session encryption (64+ chars) |
| `BLINKO_OPENAI_API_KEY` | Local | blinko | (optional) | OpenAI API key for GPT models |
| `BLINKO_GEMINI_API_KEY` | Local | blinko | (optional) | Google Gemini API key |
| `BLINKO_OPENROUTER_API_KEY` | Local | blinko | (optional) | OpenRouter API key for multi-model access |
| `TZ` | Global | Both | UTC | Timezone setting |
| `DOMAIN` | Global | blinko | localhost | Base domain for URL construction |

## Volumes & Networks

### Volumes
- **home_blinko_data**: Persistent storage for Blinko application data (`/app/.blinko`)
- **home_blinko_postgres_data**: PostgreSQL database storage

### Networks
- **home_network**: External network for Traefik routing
- **home_blinko_network**: Internal bridge network for database communication

## Stopping this App

### From the app folder:
```bash
cd apps/blinko
docker compose --env-file ../../.env --env-file .env down
```

### From the root folder:
```bash
make down-blinko
```

## Official Documentation

- **GitHub Repository**: https://github.com/blinkospace/blinko
- **Docker Hub**: https://hub.docker.com/r/blinkospace/blinko
