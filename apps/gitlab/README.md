# GitLab

GitLab is a self-hosted DevSecOps platform with source control, CI/CD, and built-in collaboration tools.

## Services

- **gitlab**: GitLab Omnibus service (web UI, API, and SSH for Git)

## Access

- Web UI: http://gitlab.${DOMAIN}
- Git over SSH: ssh -p 2222 git@<host>

## Starting this App

From the app folder:
```bash
cd apps/gitlab
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

From the root folder:
```bash
make up-gitlab
```

## Configuration

- `GITLAB_OMNIBUS_CONFIG` sets `external_url` and the advertised SSH port.
- The root admin account uses `${HOME_CLOUD_EMAIL}` and `${HOME_CLOUD_PASSWORD}` from the root `.env`.
- First startup can take several minutes while GitLab initializes.

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|--------------|--------|---------|----------------------|-------------|
| `TZ` | Global | `gitlab` | `UTC` | Timezone for the container |
| `DOMAIN` | Global | `gitlab` | `localhost` | Domain for Traefik routing |
| `HOME_CLOUD_EMAIL` | Global | `gitlab` | `admin@example.com` | Root admin email for GitLab |
| `HOME_CLOUD_PASSWORD` | Global | `gitlab` | `your_password_here` | Root admin password for GitLab |
| `GITLAB_SUBDOMAIN` | Local | `gitlab` | `gitlab` | Subdomain for Traefik routing |
| `GITLAB_SSH_PORT` | Local | `gitlab` | `2222` | Host port mapped to container SSH port 22 |
| `GITLAB_OMNIBUS_CONFIG` | Local | `gitlab` | `external_url 'http://gitlab.${DOMAIN}'; gitlab_rails['gitlab_shell_ssh_port']=2222` | Omnibus configuration string |

## Volumes & Networks

### Volumes
- `home_gitlab_data`: Application data and repositories
- `home_gitlab_config`: Omnibus configuration files
- `home_gitlab_logs`: GitLab logs

### Networks
- `home_network`: External network for Traefik routing and service discovery

## Official Documentation

https://docs.gitlab.com/ee/install/docker/
