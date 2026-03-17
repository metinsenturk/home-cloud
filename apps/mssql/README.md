# Microsoft SQL Server

Microsoft SQL Server is a relational database engine. This infrastructure service provides a shared SQL Server instance for other applications.

## Services

- **infra-mssql**: SQL Server 2025 (Linux container)

## Access

SQL Server is accessible internally via the service name `infra-mssql` on port `1433` within the `home_network`.

**External Access:** Port `1433` is exposed on the host machine for database tools like SSMS or Azure Data Studio.

**Connection String Example:**
```
Host: localhost (from host) or infra-mssql (from containers)
Port: 1433
Database: master
Username: sa
Password: <as defined in .env>
```

## Starting this App

### From the app folder:
```bash
cd apps/mssql
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-mssql
```

## Configuration

1. **Set SA Password**: Copy `.env.example` to `.env` and set a strong `MSSQL_SA_PASSWORD`.
2. **Edition Selection**: Set `MSSQL_PID` to the edition you are licensed to run (default is `Developer`).

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `ACCEPT_EULA` | Local | infra-mssql | `Y` | Accept the SQL Server EULA (required) |
| `MSSQL_SA_PASSWORD` | Local | infra-mssql | `your_strong_password_here` | SA password for SQL Server authentication |
| `MSSQL_PID` | Local | infra-mssql | `Developer` | SQL Server edition to run |

## Volumes & Networks

**Volumes:**
- `home_infra_mssql_data`: Persistent storage for SQL Server data at `/var/opt/mssql`

**Networks:**
- `home_network`: External network for cross-app communication

## Official Documentation

- https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker
- https://hub.docker.com/r/microsoft/mssql-server
