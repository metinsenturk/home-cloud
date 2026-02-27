# Metasearch

Duolingo Metasearch is a unified search aggregation tool that searches across 25+ different data sources in parallel. It provides a single interface to query multiple systems simultaneously, including GitHub, GitLab, Slack, Jira, Confluence, Notion, Jenkins, and many more.

## Services

- **metasearch**: The main application container running the Metasearch web interface and API

## Access

Once running, access Metasearch at: **http://metasearch.${DOMAIN}**

## Starting this App

### From the app folder

```bash
cd apps/metasearch
docker compose --env-file ../../.env --env-file .env up -d
```

### From the root folder

```bash
make up-metasearch
```

## Configuration

### 1. Configure API Tokens

Edit the `apps/metasearch/.env` file and add your API tokens for each service you want to search:

```bash
# Example: GitHub token
METASEARCH_GITHUB_TOKEN=ghp_yourtoken
METASEARCH_GITHUB_ORG=your-organization
```

### 2. Enable/Disable Search Engines

Edit `apps/metasearch/config.yaml` to enable or disable specific search engines:

- **To disable a source**: Comment out or delete its entire section in the config file
- **To enable a source**: Ensure its configuration is uncommented and environment variables are set

### 3. Obtain API Tokens

Each service requires different authentication methods:

- **GitHub**: Create token at [github.com/settings/tokens](https://github.com/settings/tokens) (scope: `repo`)
- **GitLab**: Create token at [gitlab.com/-/profile/personal_access_tokens](https://gitlab.com/-/profile/personal_access_tokens) (scopes: `api`, `read_user`, `read_repository`)
- **Slack**: Create app at [api.slack.com/apps](https://api.slack.com/apps) (scopes: `channels:read`, `search:read`)
- **Jira/Confluence**: Create token at [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
- **Notion**: Create integration at [notion.so/my-integrations](https://www.notion.so/my-integrations)
- **Jenkins**: Use username and API token from Jenkins user settings (optional for public instances)

### 4. Restart the Service

After updating `.env` or `config.yaml`:

```bash
make down-metasearch
make up-metasearch
```

## Environment Variables

| Variable | Source | Service | Default/Example | Description |
|----------|--------|---------|-----------------|-------------|
| `METASEARCH_PORT` | Local | metasearch | `3000` | Internal port for the application |
| `METASEARCH_GITHUB_TOKEN` | Local | metasearch | - | GitHub personal access token |
| `METASEARCH_GITHUB_ORG` | Local | metasearch | - | GitHub organization name |
| `METASEARCH_GITLAB_TOKEN` | Local | metasearch | - | GitLab personal access token |
| `METASEARCH_GITLAB_ORIGIN` | Local | metasearch | `https://gitlab.com` | GitLab instance URL |
| `METASEARCH_SLACK_TOKEN` | Local | metasearch | - | Slack OAuth token (xoxp-***) |
| `METASEARCH_SLACK_ORG` | Local | metasearch | - | Slack workspace name |
| `METASEARCH_JIRA_TOKEN` | Local | metasearch | - | Jira API token |
| `METASEARCH_JIRA_USER` | Local | metasearch | - | Jira email address |
| `METASEARCH_JIRA_ORIGIN` | Local | metasearch | - | Jira instance URL |
| `METASEARCH_CONFLUENCE_TOKEN` | Local | metasearch | - | Confluence API token |
| `METASEARCH_CONFLUENCE_USER` | Local | metasearch | - | Confluence email address |
| `METASEARCH_CONFLUENCE_ORIGIN` | Local | metasearch | - | Confluence instance URL |
| `METASEARCH_NOTION_TOKEN` | Local | metasearch | - | Notion integration token (secret_***) |
| `METASEARCH_NOTION_WORKSPACE` | Local | metasearch | - | Notion workspace ID |
| `METASEARCH_JENKINS_ORIGIN` | Local | metasearch | - | Jenkins instance URL |
| `METASEARCH_JENKINS_USER` | Local | metasearch | - | Jenkins username (optional) |
| `METASEARCH_JENKINS_TOKEN` | Local | metasearch | - | Jenkins API token (optional) |
| `METASEARCH_WEBSITE_SITEMAP` | Local | metasearch | - | Custom sitemap URL for website search (optional) |

## Volumes & Networks

### Volumes

- **home_metasearch_data**: Persistent storage for application data
- **./config.yaml**: Bind mount for search engine configuration (read-only)

### Networks

- **home_network**: External network for Traefik routing and global access

## Supported Search Engines

The following 26 data sources are supported (configure in `config.yaml`):

1. **AWS** - Tagged resources
2. **Confluence** - Documentation pages
3. **Dropbox** - Files and folders
4. **Figma** - Design files and projects
5. **GitHub** - PRs, issues, and repositories
6. **GitLab** - Merge requests and projects
7. **Google Drive** - Documents and spreadsheets
8. **Google Groups** - Mailing lists
9. **Greenhouse** - Job postings
10. **Guru** - Knowledge cards
11. **Hound** - Indexed code search
12. **Jenkins** - CI/CD job names
13. **Jira** - Issues and tickets
14. **Lingo** - Design assets
15. **Mattermost** - Team messages
16. **Notion** - Knowledge base pages
17. **Outlook Calendar** - Calendar events
18. **PagerDuty** - Schedules and services
19. **Pingboard** - Employee directory
20. **Rollbar** - Error tracking projects
21. **Slack** - Messages and channels
22. **Stack Overflow for Teams** - Questions
23. **TalentLMS** - Training courses
24. **Trello** - Boards and cards
25. **Website** - Custom sites via sitemap
26. **Zoom** - Meeting rooms

## Official Documentation

- **GitHub Repository**: [github.com/duolingo/metasearch](https://github.com/duolingo/metasearch)
- **Docker Hub**: [hub.docker.com/r/duolingo/metasearch](https://hub.docker.com/r/duolingo/metasearch)
