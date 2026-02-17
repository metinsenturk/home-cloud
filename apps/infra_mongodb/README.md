# MongoDB

MongoDB is a popular NoSQL document database that stores data in flexible, JSON-like documents. This infrastructure service provides a shared MongoDB instance that other applications can use for persistent data storage.

## Services

- **infra-mongodb**: MongoDB 8.2 document database server

## Access

MongoDB is accessible internally via the service name `infra-mongodb` on port `27017` within the `home_network`.

**External Access:** Port `27017` is also exposed on the host machine for database management tools like MongoDB Compass, Studio 3T, or the MongoDB shell.

**Connection String Example:**
```
mongodb://mongoadmin:password@localhost:27017/admin (from host)
mongodb://mongoadmin:password@infra-mongodb:27017/admin (from containers)
```

## Starting this App

### From the app folder:
```bash
cd apps/infra_mongodb
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-infra-mongodb
```

## Configuration

1. **Set Database Credentials**: Copy `.env.example` to `.env` and set a strong password:
   ```bash
   cp .env.example .env
   # Edit .env and set MONGO_INITDB_ROOT_PASSWORD to a secure value
   ```

2. **Root User**: The `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` variables create a root user in the `admin` database with superuser privileges.

3. **First Run**: On first startup, MongoDB will initialize the database. This may take a few seconds.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---------------|--------|---------|----------------------|-------------|
| `MONGO_INITDB_ROOT_USERNAME` | Local | infra-mongodb | `mongoadmin` | MongoDB root user for the admin database |
| `MONGO_INITDB_ROOT_PASSWORD` | Local | infra-mongodb | `your_secure_password_here` | MongoDB root password (required for authentication) |
| `TZ` | Global | infra-mongodb | (from root `.env`) | Timezone for the container |

## Volumes & Networks

**Volumes:**
- `home_infra_mongodb_data`: Persistent storage for MongoDB data at `/data/db`

**Networks:**
- `home_network`: External network for cross-app communication and Traefik integration

## Using MongoDB in Other Apps

When connecting from other containers in your Mini-Cloud, use the following connection settings:

```yaml
environment:
  - MONGODB_URI=mongodb://mongoadmin:${MONGO_INITDB_ROOT_PASSWORD}@infra-mongodb:27017/admin
  - MONGODB_HOST=infra-mongodb
  - MONGODB_PORT=27017
  - MONGODB_USER=mongoadmin
  - MONGODB_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
```

Make sure the application container is also connected to the `home_network`.

## Creating Application Databases and Users

You can create dedicated databases and users for each application using the MongoDB shell:

```bash
# Access MongoDB shell with root credentials
docker exec -it infra_mongodb mongosh -u mongoadmin -p "your_password" --authenticationDatabase admin

# In the MongoDB shell:
use myapp_db
db.createUser({
  user: "myapp_user",
  pwd: "secure_password",
  roles: ["readWrite"]
})
```

Or use MongoDB Compass GUI with the connection string above.

## Official Documentation

- [MongoDB Official Documentation](https://docs.mongodb.com/)
- [Docker Hub - mongo](https://hub.docker.com/_/mongo)
- [MongoDB Shell (mongosh)](https://www.mongodb.com/docs/mongodb-shell/)
