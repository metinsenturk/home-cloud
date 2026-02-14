# Host Ports
This file tracks all port mappings from the host machine to internal containers to prevent IP/Port conflicts.

## Ports Table
| Host Port | Service Name | Internal Port | Description |
| :--- | :--- | :--- | :--- |
| 80 | traefik | 80 | Main HTTP proxy entry point |
| 443 | traefik | 443 | Main HTTPS proxy entry point |
| 5432 | infra-postgres | 5432 | PostgreSQL database server for external tools |

## Notes
- **traefik**: Ports 80 and 443 must be open on the host firewall for external web traffic.
- **infra-postgres**: Port 5432 is exposed for database management tools (pgAdmin, DBeaver, etc.) from the host machine.