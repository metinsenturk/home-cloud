# Datasette

Datasette is an open-source tool for exploring and publishing SQLite data through a web UI and JSON APIs.

## Services

- `datasette`: Main Datasette web service that serves databases from `/data`.

## Access

- Web UI: `http://datasette.${DOMAIN}` (via Traefik)

## Starting this App

From the app folder:

```bash
cd apps/datasette
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

From the root folder:

```bash
make up-datasette
```

## Configuration

- Put SQLite database files in the `home_datasette_data` volume (mounted at `/data` in the container).
- Set `DATASETTE_SECRET` in `.env` to a strong random value for stable signed sessions.
- Optional secret generation command:
  - `python -c "import secrets; print(secrets.token_hex(32))"`

## Database Seeding

The included seeding script sets up multiple databases with sample data to get you started quickly.

**Using the provided scripts (Linux/WSL):**
```bash
cd apps/datasette
chmod +x seed.sh
./seed.sh
```

**Manual execution:**
```bash
cd apps/datasette
docker cp seed_database.py datasette:/tmp/seed_database.py
docker exec datasette python3 /tmp/seed_database.py
docker exec datasette rm -f /tmp/seed_database.py
```

**What gets created:**

1. **example.db** - Custom database with:
   - `people` table: Sample users with name, role, and city (3 rows)
   - `projects` table: Sample projects with status and owner (3 rows, FK to people)

2. **chinook.db** - Music store database with:
   - Artists, albums, tracks, playlists
   - Customers, invoices, sales data
   - Ideal for exploring relationships and complex queries

3. **northwind.db** - Classic sales database with:
   - Customers, orders, products
   - Employees, suppliers, categories
   - Great for business analytics demos

4. **fixtures.db** - Datasette's official test database:
   - Various data types and edge cases
   - Demonstrates Datasette features
   - Useful for testing plugins

**Access URLs:**
- `http://datasette.${DOMAIN}/example`
- `http://datasette.${DOMAIN}/chinook`
- `http://datasette.${DOMAIN}/northwind`
- `http://datasette.${DOMAIN}/fixtures`

**Adding more databases:**
Edit the `SAMPLE_DATABASES` list at the top of `seed_database.py` to include additional SQLite database URLs.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
| --- | --- | --- | --- | --- |
| `DATASETTE_SUBDOMAIN` | Local | `datasette` | `datasette` | Subdomain used by Traefik router rule. |
| `DATASETTE_DOMAIN` | Both | `datasette` | `${DOMAIN}` | Local app variable mapped from global domain value. |
| `DATASETTE_SECRET` | Local | `datasette` | `replace_with_a_long_random_secret` | Secret used by Datasette for signing cookies/tokens. |

## Volumes & Networks

- `home_datasette_data`: Persistent volume storing SQLite databases and Datasette files.
- `home_network`: External network used for Traefik routing.
- `home_datasette_network`: Internal app network for future sidecar/service expansion.

## Official Documentation

- https://docs.datasette.io/
- https://hub.docker.com/r/datasetteproject/datasette
