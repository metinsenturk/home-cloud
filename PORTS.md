# Host Ports
This file tracks all port mappings from the host machine to internal containers to prevent IP/Port conflicts.

Portrainer app also shows which ports are in use in the server. Go to http://portracker.localhost (or `http://portracker.${DOMAIN}$/`) to see more information.

## Ports Table
| Host Port | Service Name | Internal Port | Description |
| :--- | :--- | :--- | :--- |
| 80 | traefik | 80 | Main HTTP proxy entry point |
| 443 | traefik | 443 | Main HTTPS proxy entry point |
| 5432 | infra-postgres | 5432 | PostgreSQL database server for external tools |
| 1433 | infra-mssql | 1433 | Microsoft SQL Server for external tools |
| 27017 | infra-mongodb | 27017 | MongoDB database server for external tools |
| 6379 | infra-redis | 6379 | Redis in-memory data store for external tools |
| 53 | pihole | 53 (TCP/UDP) | Network-wide DNS filtering for home clients |
| 67 | pihole | 67 (UDP) | Reserved for optional Pi-hole DHCP service (currently not used) |
| 2222 | gitlab | 22 | GitLab SSH for Git operations |
| 51826 | homebridge | 51826 | HomeKit bridge for iOS device connectivity |

## Notes
- **traefik**: Ports 80 and 443 must be open on the host firewall for external web traffic.
- **infra-postgres**: Port 5432 is exposed for database management tools (pgAdmin, DBeaver, etc.) from the host machine.
- **infra-mssql**: Port 1433 is exposed for SQL Server tools (SSMS, Azure Data Studio, sqlcmd) from the host machine.
- **infra-mongodb**: Port 27017 is exposed for MongoDB tools (MongoDB Compass, Studio 3T, mongosh) from the host machine.
- **infra-redis**: Port 6379 is exposed for Redis client tools (RedisInsight, redis-cli) from the host machine.
- **pihole**: Port 53 (TCP/UDP) is exposed so LAN devices can use Pi-hole as their DNS resolver.
- **pihole-dhcp**: Port 67 (UDP) is currently not exposed/used, but is reserved for future Pi-hole DHCP mode.
- **gitlab**: Port 2222 is exposed for Git over SSH (container port 22).
- **freqtrade**: Uses dedicated PostgreSQL instance (port 5432 internal only, NOT exposed to host). FreqUI accessed via Traefik: `freqtrade.${DOMAIN}`