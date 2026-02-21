# OpenClaw - Personal AI Assistant Gateway

OpenClaw runs a self-hosted AI assistant gateway with a built-in control UI.

## Services

- **openclaw**: Gateway and Control UI (port 18789 via Traefik)

## Access

- Control UI: http://openclaw.localhost (via Traefik)

## Starting this App

Start from the app folder:

> cd apps/openclaw
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-openclaw

## Configuration

- Set `OPENCLAW_GATEWAY_TOKEN`, `TELEGRAM_BOT_TOKEN`, and `OPENROUTER_API_KEY` in `apps/openclaw/.env`.
- The gateway binds to `lan` so Traefik can reach it on `home_network`.
- WhatsApp login (QR) from the container:
  - `docker compose --env-file ../../.env --env-file .env -f docker-compose.yml exec openclaw node dist/index.js channels login --channel whatsapp`

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `OPENCLAW_SUBDOMAIN` | Local | openclaw | `openclaw` | Subdomain used for the Traefik host rule. |
| `OPENCLAW_GATEWAY_TOKEN` | Local | openclaw | `change_me` | Auth token required for non-loopback gateway access. |
| `OPENCLAW_GATEWAY_BIND` | Local | openclaw | `lan` | Gateway bind mode for container networking. |
| `OPENCLAW_GATEWAY_PORT` | Local | openclaw | `18789` | Internal gateway HTTP port used by Traefik. |
| `TELEGRAM_BOT_TOKEN` | Local | openclaw | `change_me` | Telegram bot token for the gateway. |
| `OPENROUTER_API_KEY` | Local | openclaw | `change_me` | OpenRouter API key for model access. |
| `OPENCLAW_MODEL_PRIMARY` | Local | openclaw | `openrouter/openrouter/auto` | Primary model selector for OpenClaw. |
| `DOMAIN` | Global | openclaw | `localhost` | Base domain used for Traefik host rules. |
| `TZ` | Global | openclaw | `UTC` | Time zone for the container. |

## Volumes & Networks

- **Volumes**:
  - `home_openclaw_home_data`: Persists `/home/node` for gateway data and caches
- **Networks**:
  - `home_network`: External network for Traefik routing

## Official Documentation

https://docs.openclaw.ai/
