# GitLab Local Usage

This guide shows how to use the local GitLab instance for day-to-day Git operations and how to push this repository to it.

## Prerequisites

- GitLab is running (see README for startup).
- You can reach the UI at `http://gitlab.${DOMAIN}`.
- SSH access is available on port `2222`.

## Create a Project in GitLab

1. Sign in to GitLab at `http://gitlab.${DOMAIN}`.
2. Create a new project. Example project name: `home_cloud`.
3. Note the SSH clone URL shown by GitLab, for example:
   `git@<host>:<namespace>/home_cloud.git`

## Add the GitLab Remote (Current Repo)

From the repo root:
```bash
cd d:/home_cloud

git remote add gitlab git@<host>:<namespace>/home_cloud.git
```

If you already have a `gitlab` remote, update it:
```bash
git remote set-url gitlab git@<host>:<namespace>/home_cloud.git
```

## Push to GitLab (First Push)

```bash
git push -u gitlab main
```

If your default branch is `master`:
```bash
git push -u gitlab master
```

## Push a New Branch

```bash
git checkout -b feature/gitlab-docs

git push -u gitlab feature/gitlab-docs
```

## Clone via SSH

```bash
git clone ssh://git@<host>:2222/<namespace>/home_cloud.git
```

## SSH Fingerprint and Known Hosts

On first SSH connection, you may be asked to trust the host key. If you want to pre-load it:
```bash
ssh-keyscan -p 2222 <host> >> ~/.ssh/known_hosts
```

## Troubleshooting

- **SSH connection refused**: Confirm `GITLAB_SSH_PORT=2222` and the container is running.
- **Permission denied (publickey)**: Ensure your SSH public key is added to your GitLab user profile.
- **HTTP works but SSH does not**: Verify the GitLab Omnibus config includes the correct SSH port.
