# Netdata - Real-Time Performance Monitoring

Netdata is a real-time performance monitoring and visualization tool that tracks system metrics, CPU, memory, disk, network, and more.

## Services

- **netdata**: Real-time monitoring dashboard (port 19999 via Traefik)

## Access

- Web UI: http://netdata.localhost (via Traefik)

## Starting this App

Start from the app folder:

> cd apps/netdata
> docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d

From the root folder:

> make up-netdata

## Configuration

Can be configured via environment variables. No initial configuration needed.

## Requirements

The container requires access to the host's filesystem to monitor system metrics. The following read-only mounts are used:

- `/proc`: Process and system information
- `/sys`: System kernel information
- `/etc/os-release`: OS identification

## Official Documentation

https://learn.netdata.cloud/docs
