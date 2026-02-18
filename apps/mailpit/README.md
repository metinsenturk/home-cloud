# Mailpit

Email testing tool for development and staging environments. Mailpit acts as an SMTP server that captures all outgoing emails and provides a web UI to view, search, and inspect them without sending to real recipients.

## Services

- **mailpit**: SMTP server (port 1025) and web UI (port 8025) for capturing and viewing test emails

## Access

- **Web UI**: `http://mailpit.${DOMAIN}`
- **SMTP Server**: `mailpit:1025` (accessible from other containers on `home_network`)

## Starting this App

### From the app folder:
```bash
cd apps/mailpit
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-mailpit
```

## Configuration

### Basic Setup
1. Start the service using one of the methods above
2. Access the web UI at `http://mailpit.${DOMAIN}`
3. Configure your applications to send emails to:
   - **Host**: `mailpit` (from Docker containers) or `localhost` (from host if port mapped)
   - **Port**: `1025`
   - **Authentication**: None required by default

### Optional Authentication
To protect the web UI with basic authentication:
1. Uncomment and set `MP_UI_AUTH_USER` and `MP_UI_AUTH_PASS` in `.env`
2. Restart the service

### Optional Message Limit
To limit stored messages (useful for long-running instances):
1. Uncomment and set `MP_MAX_MESSAGES` in `.env`
2. Restart the service

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `TZ` | Global | mailpit | `America/New_York` | Timezone for email timestamps |
| `MP_UI_AUTH_USER` | Local | mailpit | `admin` | Optional username for web UI authentication |
| `MP_UI_AUTH_PASS` | Local | mailpit | `your_secure_password` | Optional password for web UI authentication |
| `MP_MAX_MESSAGES` | Local | mailpit | `500` | Maximum messages to store (0 = unlimited) |
| `MP_VERBOSE` | Local | mailpit | `false` | Enable verbose logging for debugging |

## Volumes & Networks

### Volumes
- **home_mailpit_data**: Persistent storage for captured emails and application data

### Networks
- **home_network**: External network for Traefik routing and inter-service communication

## Usage Example

To configure an application to use Mailpit for email testing:

**Docker Compose Service:**
```yaml
services:
  myapp:
    environment:
      - SMTP_HOST=mailpit
      - SMTP_PORT=1025
      - SMTP_USER=
      - SMTP_PASSWORD=
```

**Python Application:**
```python
import smtplib
from email.message import EmailMessage

msg = EmailMessage()
msg['Subject'] = 'Test Email'
msg['From'] = 'sender@example.com'
msg['To'] = 'recipient@example.com'
msg.set_content('This is a test email captured by Mailpit')

with smtplib.SMTP('mailpit', 1025) as smtp:
    smtp.send_message(msg)
```

## Official Documentation

- **GitHub Repository**: https://github.com/axllent/mailpit
- **Docker Hub**: https://hub.docker.com/r/axllent/mailpit
