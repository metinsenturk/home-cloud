# Makefile Guide

> **Complete guide to using the Mini-Cloud Makefile for managing your self-hosted infrastructure**

## 📋 Table of Contents
- [What is This?](#what-is-this)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Command Categories](#command-categories)
  - [🔧 Setup & Validation](#-setup--validation)
  - [🚀 Launching Services](#-launching-services)
  - [⛔ Stopping Services](#-stopping-services)
  - [📦 Custom Groups](#-custom-groups)
  - [🧪 Testing](#-testing)
- [Working with Groups](#working-with-groups)
- [Tips & Best Practices](#tips--best-practices)
- [Troubleshooting](#troubleshooting)

---

## What is This?

The **Makefile** is the command center for your entire Mini-Cloud infrastructure. It orchestrates Docker Compose commands across multiple applications, each living in its own directory under `apps/`.

**Key Features:**
- 🎯 **Modular Design** - Each app is independent but shares a common network
- 🔄 **Environment Management** - Automatic loading of root + app-specific `.env` files
- 🏗️ **Custom Groups** - Launch related apps together (e.g., "data-tools", "monitoring")
- ✅ **Testing Support** - Built-in unit and integration tests for infrastructure validation
- 🌐 **Network Orchestration** - All services connect via the `home_network` bridge

**Architecture:**
```
home-cloud/
├── Makefile           ← You are here (command center)
├── .env              ← Global environment variables
├── apps/             ← Individual applications
│   ├── traefik/      ← Reverse proxy (base service)
│   ├── dozzle/       ← Log viewer (base service)
│   ├── blinko/       ← Example app
│   └── ...
├── groups.mk         ← Optional: Custom app groups (Make format)
└── groups.yaml       ← Optional: Custom app groups (YAML format)
```

---

## Prerequisites

### Required Tools
- **GNU Make** (3.81+)
- **Docker Engine** (20.10+)
- **Docker Compose v2** (`docker compose` command, not `docker-compose`)
- **bash** shell

### Optional Tools
- **yq** - Required only when using the YAML groups backend (`GROUPS_BACKEND=yaml`)
- **bats-core** - Required only for running tests (`make test-makefile`)
- **GNU parallel** - Optional for parallel test execution

### Verify Dependencies
Run this command to check which tools are installed:
```bash
make check-tools
```

Example output:
```
=== REQUIRED Tools ===
✓ docker
✓ docker compose
✓ make
✓ bash

=== OPTIONAL Tools ===
✓ bats (testing: make test-makefile)
✗ GNU parallel (optional, for parallel test execution)
✓ yq (optional, for: GROUPS_BACKEND=yaml)
```

---

## Quick Start

### 1. Navigate to Repository Root
```bash
cd /path/to/home-cloud
```
⚠️ **All make commands MUST be run from the repository root directory.**

### 2. Initialize Global Environment File
```bash
make init-env
```
Creates root `.env` from `.env.example` for first-time setup.

### 3. Create the Shared Network
```bash
make create-network
```
This creates the `home_network` bridge that all services use to communicate.

### 4. Launch Base Services
```bash
make up-base
```
This starts the foundational services:
- **Traefik** - Reverse proxy for routing
- **Dozzle** - Log viewer
- **WUD** - What's Up Docker (update monitoring)

### 5. Launch Individual Apps
```bash
make up-blinko      # Start Blinko app
make up-jupyter     # Start Jupyter notebook
make up-metabase    # Start Metabase analytics
```

### 6. Stop Services When Done
```bash
make down-blinko    # Stop specific app
make down-base      # Stop base services
```

---

## Command Categories

### 🔧 Setup & Validation

#### Initialize Global Environment
```bash
make init-env
```
Creates root `.env` from `.env.example`.

Safety behavior:
- Fails if `.env` already exists (prevents accidental secret overwrite)
- Fails if `.env.example` is missing

#### Create Shared Network
```bash
make create-network
```
Creates the `home_network` bridge if it doesn't exist. All services connect to this network.

#### Validate App Configuration
```bash
make check-validity APP=blinko
```
Checks if an app's `docker-compose.yml` file is valid before launching it.

#### Check Installed Tools
```bash
make check-tools
```
Displays status of required and optional dependencies.

---

### 🚀 Launching Services

#### Start Base Services
```bash
make up-base
```
Launches: Traefik + Dozzle + WUD

#### Start Individual Apps
```bash
make up-<appname>
```

**Examples:**
```bash
make up-blinko          # Note-taking
make up-metabase        # Analytics
make up-jupyter         # Notebooks
make up-infra-postgres  # PostgreSQL database
make up-glance          # Dashboard
make up-memos           # Memo app
```

#### Start All Services
```bash
make up-all
```
⚠️ Launches **every configured app** in sequence. This can take several minutes and consume significant resources.

---

### ⛔ Stopping Services

#### Stop Individual Apps
```bash
make down-<appname>
```

**Examples:**
```bash
make down-blinko
make down-metabase
make down-jupyter
```

#### Stop Base Services
```bash
make down-base
```

#### Stop All Services
```bash
make down-all
```
Stops all services in reverse order (safe teardown).

---

### 📦 Custom Groups

Groups let you launch related apps together. For example, create a "data-tools" group containing Jupyter, Metabase, and Datasette.

#### Initialize Group Configuration
```bash
make init-groups
```
Creates `groups.mk` from `groups.mk.example` (default backend).

You can set the default backend globally in root `.env`:
```env
HOME_CLOUD_GROUPS_BACKEND=make
# or
HOME_CLOUD_GROUPS_BACKEND=yaml
```
Precedence order is: command-line `GROUPS_BACKEND=...` → process environment `GROUPS_BACKEND` → `.env` (`HOME_CLOUD_GROUPS_BACKEND`) → fallback `make`.

**Or use YAML format (recommended for readability):**
```bash
make init-groups GROUPS_BACKEND=yaml
```
Creates `groups.yaml` from `groups.yaml.example`.

#### List Available Groups
```bash
make list-groups
```

Example output:
```
Available groups (make) from groups.mk: favorites data-tools monitoring
```

#### Start/Stop Groups
```bash
make up-group-favorites     # Start all apps in "favorites" group
make down-group-favorites   # Stop all apps in "favorites" group
```

#### Shortcut Aliases
```bash
make up-favorites           # Same as: make up-group-favorites
make down-favorites         # Same as: make down-group-favorites
```

#### Remove Group Configuration
```bash
make clean-groups
```

See [Working with Groups](#working-with-groups) section for detailed setup instructions.

---

### 🧪 Testing

The Makefile includes comprehensive test suites to validate infrastructure behavior.

#### Run Unit Tests
```bash
make test-makefile
```
Fast, safe tests using mocked Docker (no real containers). ~15-20 seconds.

#### Run Integration Tests (Quick)
```bash
RUN_INTEGRATION=1 make test-makefile-integration-quick
```
Quick validation with real Docker. ~30-60 seconds.

#### Run Integration Tests (Full)
```bash
RUN_INTEGRATION=1 make test-makefile-integration-full
```
Complete lifecycle tests. ~3-5 minutes.

#### Run All Tests
```bash
make test-makefile-all                           # Unit tests only
RUN_INTEGRATION=1 make test-makefile-all         # Unit + integration (quick)
```

#### Parallel Execution (Faster)
```bash
BATS_PARALLEL=1 RUN_INTEGRATION=1 make test-makefile-integration-quick
```
Requires GNU parallel to be installed.

See [tests/README.md](tests/README.md) for detailed testing documentation.

---

## Working with Groups

Custom groups allow you to manage sets of related applications together.

### Concept

Instead of running:
```bash
make up-blinko
make up-glance
make up-memos
```

You can define a "favorites" group and run:
```bash
make up-group-favorites
```

### Setup (Make Backend - Default)

**1. Create group configuration:**
```bash
make init-groups
```

**2. Edit `groups.mk`:**
```makefile
# Define group names
GROUPS := favorites data-tools monitoring

# Define apps in each group
GROUP_favorites := blinko glance memos
GROUP_data_tools := jupyter metabase datasette
GROUP_monitoring := netdata dozzle beszel
```

**3. Use your groups:**
```bash
make list-groups                # See available groups
make up-group-favorites         # Launch favorites
make down-group-monitoring      # Stop monitoring
```

### Setup (YAML Backend - Recommended for Readability)

**1. Create YAML configuration:**
```bash
make init-groups GROUPS_BACKEND=yaml
```

**2. Edit `groups.yaml`:**
```yaml
groups:
  favorites:
    - blinko
    - glance
    - memos
  data-tools:
    - jupyter
    - metabase
    - datasette
  monitoring:
    - netdata
    - dozzle
    - beszel
```

**3. Use your groups:**
```bash
make list-groups GROUPS_BACKEND=yaml
make up-group-favorites GROUPS_BACKEND=yaml
```

### Backend Comparison

| Feature | Make Backend | YAML Backend |
|---------|--------------|--------------|
| **Dependency** | None (built-in) | Requires `yq` |
| **File Format** | `groups.mk` (Makefile syntax) | `groups.yaml` (YAML syntax) |
| **Default** | ✅ Yes | No |
| **Syntax** | Make variables | YAML structure |

**Recommendation:** Keep **Make backend** as default for dependency-free behavior, but prefer **YAML backend** for readability and easier editing.

---

## Tips & Best Practices

### 🎯 Always Run from Root
```bash
# ✅ Correct
cd /path/to/home-cloud
make up-blinko

# ❌ Wrong (will fail)
cd apps/blinko
make up-blinko
```

### 🔍 Validate Before Launch
```bash
make check-validity APP=newapp
```
Always validate new apps before launching to catch configuration errors early.

### 🐢 Start Small, Scale Up
```bash
# Start with base services
make up-base

# Add apps incrementally
make up-blinko
make up-memos

# Full stack only when needed
make up-all
```

### 📊 Monitor Resource Usage
```bash
# View logs across all services
# Access Dozzle at: http://logs.yourdomain.local

# Monitor system resources
make up-netdata
# Access at: http://netdata.yourdomain.local
```

### 🔐 Environment Variables
Each app loads environment variables in this order:
1. **Root `.env`** - Global variables
2. **App `.env`** - App-specific overrides (in `apps/<appname>/.env`)

Variables in the app `.env` always take priority over root `.env`.

### 🧹 Clean Shutdown
```bash
# Always use down commands to gracefully stop services
make down-blinko      # Proper shutdown
# vs
docker kill blinko    # Abrupt termination (not recommended)
```

### 🚀 Custom Groups Strategy
Create groups by purpose:
- **daily-use**: Apps you need every day
- **dev-tools**: Development environment
- **data-pipeline**: ETL and analytics
- **monitoring**: System monitoring stack

---

## Troubleshooting

### Command Not Found
```
make: *** No rule to make target `up-myapp'. Stop.
```
**Solution:** Verify the app name. List available apps with:
```bash
ls apps/
```

### Network Doesn't Exist
```
Error: network home_network not found
```
**Solution:** Create the network first:
```bash
make create-network
```

### Docker Compose Command Failed
```
Error: docker compose command not recognized
```
**Solution:** Ensure you have Docker Compose v2 installed:
```bash
docker compose version
```
If you only have v1 (`docker-compose`), upgrade to v2.

### Group Not Found
```
✗ Error: group 'favorites' not found or empty
```
**Solution:** 
1. Ensure group file exists: `ls groups.mk` or `ls groups.yaml`
2. Verify group is defined in the file
3. Run `make list-groups` to see available groups

### Test Failures
```
✗ Error: bats is required
```
**Solution:** Install bats:
```bash
# Ubuntu/WSL
sudo apt-get install -y bats

# macOS
brew install bats-core
```

### App Won't Start
**Debug checklist:**
1. Validate configuration: `make check-validity APP=appname`
2. Check if network exists: `docker network ls | grep home_network`
3. Verify `.env` files exist in root and `apps/appname/`
4. Check logs: View in Dozzle or `docker logs <container-name>`

---

## Next Steps

✅ **You're ready!** Try these commands:

```bash
make init-env                     # Create .env from .env.example (one-time)
make create-network              # Set up networking
make up-base                     # Launch core services
make up-blinko                   # Try launching an app
make list-groups                 # Explore custom groups (if configured)
```

📚 **Further Reading:**
- [tests/README.md](tests/README.md) - Testing infrastructure guide
- [.github/testing-instructions.md](.github/testing-instructions.md) - Contributor testing guidelines
- [apps/*/README.md](apps/) - Individual app documentation

---

<div align="center">

**Questions or issues?** Check app-specific README files in `apps/<appname>/`

</div>
