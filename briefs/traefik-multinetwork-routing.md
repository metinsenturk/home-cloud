---
title: Traefik Multi-Network Routing Fix
description: Resolving 504 Gateway Timeouts when services connect to multiple networks
created: 2026-02-11
updated: 2026-02-11
tags:
  - traefik
  - docker
  - networking
  - reverse-proxy
category: DevOps
references:
  - https://doc.traefik.io/traefik/providers/docker/
---

# Traefik Multi-Network Routing Fix

## Problem

When a container is connected to multiple Docker networks (e.g., a reverse proxy network and an internal app network), Traefik may route traffic to the container's IP on the wrong network, resulting in **504 Gateway Timeouts**.

### Example Scenario

A web service `myapp` is connected to:
- `proxy_network` (external, connects to Traefik)
- `myapp_network` (internal, for inter-service communication)

Traefik might try to route to `myapp` via the internal `myapp_network` IP instead of the `proxy_network` IP, causing the routing to fail.

## Solution

Add the `traefik.docker.network` label to explicitly tell Traefik which network to use for routing:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=proxy_network"
  - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

The value of `traefik.docker.network` must match the network name that Traefik itself is connected to (typically the external proxy/bridge network).

## Complete Example

```yaml
services:
  myapp:
    image: myapp:latest
    container_name: myapp
    restart: unless-stopped
    networks:
      - proxy_network      # External network for Traefik
      - myapp_network      # Internal network for app communication
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy_network"  # ← Explicitly set the network
      - "traefik.http.routers.myapp.rule=Host(`myapp.localhost`)"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
    environment:
      - PORT=8080

networks:
  proxy_network:
    external: true  # Created manually or by another service
  myapp_network:
    name: myapp_network
    driver: bridge

```

## Key Points

1. **Only add the label if the container has multiple networks**: Single-network services don't need this.
2. **Match the proxy network name**: The value must exactly match the network name where Traefik runs.
3. **It's the external network**: Use the label for the network that connects to Traefik, not internal networks.
4. **Common names**: `home_network`, `proxy_network`, `traefik_network`, etc.

## References

- Official Traefik Docker documentation: https://doc.traefik.io/traefik/providers/docker/
