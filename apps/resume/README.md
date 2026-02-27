# Reactive Resume

A free and open-source resume builder that simplifies the process of creating, updating, and sharing resumes. Built with privacy as a core principle, giving you complete ownership of your data.

## Services

- **resume**: Main web application built with React 19 and TanStack Start providing the resume builder interface
- **resume-db**: Dedicated PostgreSQL database (Alpine) for storing user accounts, resumes, and application data
- **resume-browserless**: Chromium headless browser service for generating PDF exports and resume previews
- **resume-seaweedfs**: S3-compatible distributed storage system for file uploads and asset management
- **resume-seaweedfs-bucket**: One-time initialization service that creates the required S3 bucket

## Access

- **URL**: `http://resume.${DOMAIN}`
- **First Access**: Create your account through the web interface and start building your resume immediately

## Starting this App

### From the app folder:
```bash
cd apps/resume
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:
```bash
make up-resume
```

## Configuration

### Required Environment Variables

All app-specific variables must be set in the local `.env` file before starting:

1. **Database Credentials**: Set secure values for `RESUME_DB_NAME`, `RESUME_DB_USER`, and `RESUME_DB_PASSWORD`
2. **Authentication Secret**: Generate a secure random string (minimum 32 characters) for `RESUME_AUTH_SECRET`
3. **Browserless Token**: Set a secure token for `RESUME_BROWSERLESS_TOKEN`
4. **S3 Credentials**: Configure `RESUME_S3_ACCESS_KEY` and `RESUME_S3_SECRET_KEY` (defaults work for local deployment)

### Initial Setup

1. Copy `.env.example` to `.env` and update all values with secure credentials
2. Start all services using the commands above
3. Access the application at `resume.${DOMAIN}`
4. Create your admin account on first visit
5. Start building your resume with real-time preview

### Features

- Real-time preview as you type
- Multiple export formats (PDF, JSON)
- Drag-and-drop section ordering
- Custom sections for any content type
- Rich text editor with formatting support
- Multiple professionally designed templates
- AI integration (OpenAI, Google Gemini, Anthropic Claude)
- Multi-language support
- Share resumes via unique links

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---|---|---|---|---|
| `TZ` | Global | resume | `UTC` | Timezone for the application |
| `DOMAIN` | Global | resume | `localhost` | Domain used in Traefik routing and APP_URL |
| `RESUME_DB_NAME` | Local | resume-db, resume | `reactive_resume` | PostgreSQL database name |
| `RESUME_DB_USER` | Local | resume-db, resume | `resume_user` | PostgreSQL database user |
| `RESUME_DB_PASSWORD` | Local | resume-db, resume | - | PostgreSQL database password (must be secure) |
| `RESUME_AUTH_SECRET` | Local | resume | - | Application authentication secret key (min 32 chars) |
| `RESUME_BROWSERLESS_TOKEN` | Local | resume-browserless, resume | - | Token for securing browserless service access |
| `RESUME_S3_ACCESS_KEY` | Local | resume-seaweedfs, resume | `seaweedfs` | S3-compatible storage access key |
| `RESUME_S3_SECRET_KEY` | Local | resume-seaweedfs, resume | `seaweedfs` | S3-compatible storage secret key |

## Volumes & Networks

### Volumes

| Name | Purpose |
|---|---|
| `home_resume_data` | Application data and runtime files |
| `home_resume_db_data` | PostgreSQL database persistent storage |
| `home_resume_seaweedfs_data` | SeaweedFS distributed file storage for uploads and assets |

### Networks

| Name | Type | Purpose |
|---|---|---|
| `home_network` | External | Traefik routing for external access |
| `home_resume_network` | Internal | Private bridge for service-to-service communication |

## Official Documentation

- [Reactive Resume GitHub Repository](https://github.com/amruthpillai/reactive-resume)
- [Official Documentation](https://docs.rxresu.me/)
- [Self-Hosting Guide](https://docs.rxresu.me/self-hosting/docker)
- [Development Setup](https://docs.rxresu.me/contributing/development)
- [Project Architecture](https://docs.rxresu.me/overview/architecture)
