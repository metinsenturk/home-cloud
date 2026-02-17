# GitLab Local Usage

This guide provides step-by-step instructions for setting up and using your local GitLab instance for day-to-day Git operations.

## Prerequisites

- GitLab is running (see README for startup)
- You can reach the UI at `http://gitlab.${DOMAIN}`
- SSH access is available on port `2222`

---

## Part 1: Initial Setup

### Step 1: Generate or Locate Your SSH Key

**Option A: Create a new SSH key**
```bash
# Generate a new SSH key pair (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (recommended) or leave empty
```

**Option B: Use an existing SSH key**
```bash
# Check for existing keys
ls -la ~/.ssh

# Look for files like: id_rsa.pub, id_ed25519.pub, id_ecdsa.pub
```

### Step 2: Copy Your SSH Public Key

```bash
# Display your public key
cat ~/.ssh/id_ed25519.pub

# Or for RSA keys
cat ~/.ssh/id_rsa.pub
```

Copy the entire output (starts with `ssh-ed25519` or `ssh-rsa`).

### Step 3: Add SSH Key to GitLab

1. Sign in to GitLab at `http://gitlab.${DOMAIN}`
2. Click your avatar (top-right) → **Preferences**
3. In the left sidebar, click **SSH Keys**
4. Paste your public key into the **Key** field
5. Add a descriptive **Title** (e.g., "Home Laptop")
6. Set an **Expiration date** (optional, recommended for security)
7. Click **Add key**

### Step 4: Configure SSH for GitLab

Add GitLab to your SSH config for easier access:

```bash
# Create or edit SSH config
nano ~/.ssh/config
```

Add the following configuration:

```
# Local GitLab Instance
Host gitlab.localhost
  HostName gitlab.localhost
  Port 2222
  User git
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile ~/.ssh/known_hosts
```

**Note**: Replace `gitlab.localhost` with your actual `${DOMAIN}` value if different.

Save and exit (`Ctrl+X`, then `Y`, then `Enter`).

### Step 5: Add GitLab to Known Hosts

Pre-load GitLab's SSH fingerprint to avoid the trust prompt:

```bash
# Add GitLab's host key to known_hosts
ssh-keyscan -p 2222 gitlab.localhost >> ~/.ssh/known_hosts
```

### Step 6: Test SSH Connection

```bash
# Test the connection
ssh -T gitlab.localhost

# Expected output:
# Welcome to GitLab, @username!
```

If you see "Permission denied", review Step 3 and ensure your public key is added correctly.

---

## Part 2: Working with Repositories

### Step 7: Create a Project in GitLab

1. Sign in to GitLab at `http://gitlab.${DOMAIN}`
2. Click **New project** (or the **+** icon in the top navigation)
3. Choose **Create blank project**
4. Enter project details:
   - **Project name**: `home_apps` (example)
   - **Visibility**: Private (recommended)
5. Click **Create project**
6. Note the SSH clone URL displayed (e.g., `git@gitlab.localhost:root/home_apps.git`)

### Step 8: Add GitLab Remote to Existing Repository

If you have an existing local repository:

```bash
# Navigate to your repository
cd /path/to/your/repo

# Add GitLab as a remote
git remote add gitlab git@gitlab.localhost:root/home_apps.git

# Verify remotes
git remote -v
```

**If the remote already exists**, update it:
```bash
git remote set-url gitlab git@gitlab.localhost:root/home_apps.git
```

### Step 9: Push to GitLab (Initial Push)

```bash
# Push your main branch to GitLab
git push -u gitlab main

# If your default branch is 'master'
git push -u gitlab master
```

**Explanation**: The `-u` flag sets GitLab as the upstream for your branch, so future pushes can use `git push` without arguments.

### Step 10: Push a New Branch

```bash
# Create a new branch
git checkout -b feature/new-feature

# Make your changes, then commit
git add .
git commit -m "Add new feature"

# Push the branch to GitLab
git push -u gitlab feature/new-feature
```

### Step 11: Clone a Repository from GitLab

To clone a project from GitLab to a new location:

**Using SSH config alias:**
```bash
git clone git@gitlab.localhost:root/home_apps.git
```

**Using full SSH URL:**
```bash
git clone ssh://git@gitlab.localhost:2222/root/home_apps.git
```

**Clone to a specific directory:**
```bash
git clone git@gitlab.localhost:root/home_apps.git /path/to/destination
```

---

## Part 3: Daily Workflows

### Fetch and Pull Changes

```bash
# Fetch updates from GitLab
git fetch gitlab

# Pull and merge changes
git pull gitlab main
```

### Push Changes

```bash
# After committing locally
git push gitlab

# Or specify branch explicitly
git push gitlab feature-branch
```

### Create Merge Request (via Web UI)

1. Push your feature branch to GitLab
2. Visit `http://gitlab.${DOMAIN}`
3. Navigate to your project
4. Click **Create merge request** (banner appears after pushing)
5. Fill in title and description
6. Assign reviewers (optional)
7. Click **Create merge request**

### View All Remotes

```bash
# List configured remotes
git remote -v

# Example output:
# gitlab    git@gitlab.localhost:root/home_apps.git (fetch)
# gitlab    git@gitlab.localhost:root/home_apps.git (push)
# origin    https://github.com/user/repo.git (fetch)
# origin    https://github.com/user/repo.git (push)
```

---

## Troubleshooting

### SSH Connection Refused
```bash
# Check if GitLab container is running
docker ps | grep gitlab

# Verify SSH port mapping
docker port gitlab 22

# Expected output: 0.0.0.0:2222 -> 22/tcp
```

**Solution**: Confirm `GITLAB_SSH_PORT=2222` in `.env` and restart GitLab if needed.

### Permission Denied (publickey)
```bash
# Test SSH connection with verbose output
ssh -Tv gitlab.localhost
```

**Common causes**:
- SSH public key not added to GitLab profile (see Step 3)
- Wrong private key being used (check `IdentityFile` in SSH config)
- SSH agent not running or key not loaded

**Solution**: 
```bash
# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Host Key Verification Failed
```bash
# Remove old host key
ssh-keygen -R "[gitlab.localhost]:2222"

# Re-add current host key
ssh-keyscan -p 2222 gitlab.localhost >> ~/.ssh/known_hosts
```

### HTTP Works but SSH Does Not
Check the GitLab configuration file:
```bash
# View current SSH port configuration
docker exec -it gitlab grep "gitlab_shell_ssh_port" /etc/gitlab/gitlab.rb

# Expected output: gitlab_rails['gitlab_shell_ssh_port'] = 2222
```

**Solution**: Verify `gitlab.rb` contains `gitlab_rails['gitlab_shell_ssh_port'] = 2222` and reconfigure if needed:
```bash
docker exec -it gitlab gitlab-ctl reconfigure
```

### Clone URL Shows Wrong Port
If the GitLab UI shows `ssh://git@gitlab.localhost:22/...` instead of port `2222`, the SSH port configuration needs adjustment.

**Solution**: Update `gitlab.rb` and reconfigure (see above).

---

## Quick Reference

### Common Commands
```bash
# Add remote
git remote add gitlab git@gitlab.localhost:username/repo.git

# Push to GitLab
git push gitlab main

# Pull from GitLab
git pull gitlab main

# Clone from GitLab
git clone git@gitlab.localhost:username/repo.git

# Test SSH connection
ssh -T gitlab.localhost
```

### SSH Config Template
```
Host gitlab.localhost
  HostName gitlab.localhost
  Port 2222
  User git
  IdentityFile ~/.ssh/id_ed25519
```

### Useful GitLab Commands
```bash
# View GitLab version
docker exec -it gitlab gitlab-rake gitlab:env:info

# Check GitLab status
docker exec -it gitlab gitlab-ctl status

# Reconfigure GitLab
docker exec -it gitlab gitlab-ctl reconfigure

# View logs
docker logs gitlab --tail 100 -f
```
