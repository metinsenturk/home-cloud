# Redash - First Startup Setup Guide

Quick start guide to get Redash running on first deployment.

## Summary of Tasks

| # | Task | Time |
|---|------|------|
| 1 | Configure app environment variables | ~2 min |
| 2 | Start Redash services | ~2 min |
| 3 | Initialize database schema | ~1 min |
| 4 | Create admin user via UI | ~2 min |

**Total Time:** ~7 minutes

---

## Step 1: Configure App Environment Variables

Update the `.env` file in `apps/redash/` with required configuration.

### Generate Secure Secrets

Generate a random cookie secret:
```bash
openssl rand -hex 32
```

Generate a strong database password:
```bash
openssl rand -base64 32
```

### Edit `.env`

```bash
nano apps/redash/.env
```

Update with your generated values:
```dotenv
REDASH_DB_PASSWORD=your_strong_password_here
REDASH_COOKIE_SECRET=your_generated_hex_here
```

### Verify Global SMTP Configuration

Ensure these variables exist in your **root `.env`** (required for email notifications):

```bash
grep "HOME_CLOUD_SMTP" .env
```

You should see:
```
HOME_CLOUD_SMTP_HOST=...
HOME_CLOUD_SMTP_PORT=...
HOME_CLOUD_SMTP_USER=...
HOME_CLOUD_SMTP_PASSWORD=...
HOME_CLOUD_EMAIL=...
```

If missing, add them to the root `.env`:
```dotenv
HOME_CLOUD_SMTP_HOST=smtp.gmail.com
HOME_CLOUD_SMTP_PORT=587
HOME_CLOUD_SMTP_USER=your-email@gmail.com
HOME_CLOUD_SMTP_PASSWORD=your-app-password
HOME_CLOUD_EMAIL=noreply@example.com
```

---

## Step 2: Start Redash Services

### Start from Root Directory

```bash
make up-redash
```

### Or from App Directory

```bash
cd apps/redash
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### Verify Services Started

```bash
docker compose --env-file .env --env-file apps/redash/.env -f apps/redash/docker-compose.yml ps
```

All containers should show `healthy` or `up` status. Wait 30-60 seconds for full initialization.

---

## Step 3: Initialize Database Schema

Create the database tables:

```bash
docker exec redash /app/manage.py database create_tables
```

**Expected output:**
```
[DATE][PID][INFO][alembic.runtime.migration] Context impl PostgresqlImpl.
[DATE][PID][INFO][alembic.runtime.migration] Running stamp_revision...
```

### Verify Tables Created

```bash
docker exec redash_postgres psql -U redash -d redash -c "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='public';"
```

Should show:
```
 table_count
-------------
          20
```

---

## Step 4: Create Admin User via UI

Redash is now accessible at: **`https://redash.${DOMAIN}`**

(Replace `${DOMAIN}` with your actual domain from root `.env`)

### Access Redash

1. Open your browser and navigate to `https://redash.${DOMAIN}`
2. You'll see the login page
3. Click the link to create your first admin account
4. Fill in the form with your desired credentials
5. Click **"Create Account"**

### You're Done!

You can now log in and start using Redash.

---

## Alternative: Create Admin User via CLI

If you prefer creating the admin account from command line:

```bash
docker exec redash /app/manage.py users create_root \
  your-email@example.com \
  "Your Name" \
  --password "YourStrongPassword123!" \
  --org "default"
```

Verify user was created:
```bash
docker exec redash /app/manage.py users list
```

---

## Troubleshooting

### Container Issues

```bash
# Check container status
docker compose --env-file .env --env-file apps/redash/.env -f apps/redash/docker-compose.yml ps

# View logs
docker logs redash
```

### Database Connection Error

```bash
# Verify PostgreSQL is healthy
docker exec redash_postgres pg_isready -U redash -d redash
```

### Change Admin Password

```bash
docker exec redash /app/manage.py users password your-email@example.com new_password
```

---

## Next Steps

1. Connect data sources (Settings → Data Sources)
2. Create your first query
3. Build dashboards
4. Invite team members

See [README.md](README.md) for more details.
