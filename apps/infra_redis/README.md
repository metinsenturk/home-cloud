# Redis (Infrastructure)

Redis is an open-source, in-memory data structure store used as a database, cache, message broker, and streaming engine. This is a shared infrastructure service available to all applications in the home-cloud environment.

## Services

| Service | Description |
|---------|-------------|
| **infra-redis** | Redis server with password authentication and persistence enabled |

## Access

- **Internal Access:** Applications can connect via service name `infra-redis` on port `6379`
- **External Access:** Port `6379` is exposed on the host for Redis client tools
- **Authentication:** Password-protected (set via `INFRA_REDIS_PASSWORD`)

## Starting this App

### From the app folder:
```bash
cd apps/infra_redis
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-infra-redis
```

## Configuration

### Connection String Format
Applications should connect to Redis using:
```
redis://:password@infra-redis:6379
```

Or for applications that require separate parameters:
- **Host**: `infra-redis` (or `localhost` from host machine)
- **Port**: `6379`
- **Password**: Value from `INFRA_REDIS_PASSWORD`
- **Database**: `0` (default) or specify 0-15

### Persistence
Redis is configured with both RDB snapshots and AOF (Append Only File):
- **RDB**: Periodic snapshots to `/data/dump.rdb`
- **AOF**: All write operations logged to `/data/appendonly.aof`
- **Data Directory**: Mounted to `home_infra_redis_data` volume

### Security
- Password authentication is **required** for all connections
- Set a strong password in `.env` before starting
- Change the default password immediately after first deployment

### Redis CLI Usage

#### From Host Machine
```bash
# Connect from host
redis-cli -h localhost -p 6379 -a your_password_here

# Or using environment variable
redis-cli -h localhost -p 6379 --askpass
```

#### From Container
```bash
# Execute commands directly
docker exec infra_redis redis-cli -a your_password_here ping

# Interactive shell
docker exec -it infra_redis redis-cli -a your_password_here
```

### Common Redis Commands
```bash
# Test connection
PING

# Set a key
SET mykey "Hello"

# Get a key
GET mykey

# List all keys (use with caution in production)
KEYS *

# Get server info
INFO

# Monitor commands in real-time
MONITOR
```

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|----------------------|-------------|
| `TZ` | Global | infra-redis | `UTC` | Timezone for logs and timestamps |
| `INFRA_REDIS_PASSWORD` | Local | infra-redis | N/A | Password for Redis authentication (required) |

## Volumes & Networks

### Volumes
- **home_infra_redis_data**: Persistent storage for Redis data files (RDB + AOF) at `/data`

### Networks
- **home_network**: External network for cross-app communication (apps connect via `infra-redis:6379`)
- **home_infra_redis_network**: Internal network for isolation

### Ports
- **6379** (TCP): Exposed to host for external Redis client tools (RedisInsight, redis-cli, etc.)

## Integration Examples

### Node.js (ioredis)
```javascript
const Redis = require('ioredis');
const redis = new Redis({
  host: 'infra-redis',
  port: 6379,
  password: process.env.INFRA_REDIS_PASSWORD,
  db: 0
});
```

### Python (redis-py)
```python
import redis
r = redis.Redis(
    host='infra-redis',
    port=6379,
    password=os.getenv('INFRA_REDIS_PASSWORD'),
    db=0,
    decode_responses=True
)
```

### Docker Compose Integration
Other apps should reference Redis in their environment:
```yaml
environment:
  - REDIS_HOST=infra-redis
  - REDIS_PORT=6379
  - REDIS_PASSWORD=${INFRA_REDIS_PASSWORD}
networks:
  - home_network
```

## Notes

- **Performance**: Redis is single-threaded; suitable for most workloads but consider clustering for high-volume scenarios
- **Memory**: Monitor memory usage with `INFO memory` command
- **Persistence**: AOF provides better durability but slightly impacts performance
- **Updates**: Container updates are managed by What's Up Docker (WUD)
- **Backup**: Data is stored in `home_infra_redis_data` volume - back up regularly
- **No Web UI**: Redis has no built-in web interface; use external tools like RedisInsight or redis-cli

## External Tools

### RedisInsight (Recommended GUI)
- Download: https://redis.io/insight/
- Connect to: `localhost:6379` with password

### redis-cli
```bash
# Install on host (Debian/Ubuntu)
sudo apt-get install redis-tools

# Connect
redis-cli -h localhost -p 6379 -a your_password
```

## Official Documentation

- **Redis:** https://redis.io/
- **Docker Image:** https://hub.docker.com/_/redis
- **Commands Reference:** https://redis.io/commands/
- **Persistence:** https://redis.io/topics/persistence
