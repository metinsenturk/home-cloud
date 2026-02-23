---
title: Docker Compose Keys: user, group_add, and extra_hosts
description: How to use user, group_add, and extra_hosts in Docker Compose, with security notes and examples.
created: 2026-02-22
updated: 2026-02-22
tags:
  - docker
  - compose
  - containers
  - networking
  - permissions
  - users
category: Docker
references:
  - https://docs.docker.com/compose/compose-file/05-services/
  - https://docs.docker.com/engine/reference/run/#add-host
---

# Overview

`user`, `group_add`, and `extra_hosts` are service-level keys in Docker Compose. All three are powerful but easy to misuse, so the brief focuses on when to use them, how they work, and safe patterns.

# user

## What it does

`user` sets the UID and GID for the main container process, similar to `docker run --user`. It controls which Linux user and primary group the process runs as, which affects file ownership and permission checks for volumes, sockets, and device files.

## Does the user have to exist in the container?

Not always. If you set a numeric UID and GID (for example, `"1000:1000"`), the process can run with those IDs even if no matching user or group exists in `/etc/passwd` or `/etc/group` inside the container. However, some software expects a named user to exist (for example, it may look up the home directory or shell), so numeric IDs are safest when you only care about permissions.

## Example

```yaml
services:
  app:
    image: alpine:3.20
    user: "1000:1000"
    volumes:
      - ./data:/data
    command: ["sh", "-c", "id && touch /data/owned-by-1000"]
```

## Notes and pitfalls

- `user` sets the primary group, not supplemental groups. Use `group_add` for extra group membership.
- If a service expects a specific username to exist, use a base image that creates that user or add it in a custom image.
- `user` does not change file ownership on the host; it only changes how the container process sees permissions.

# group_add

## What it does

`group_add` adds supplemental Linux groups to the container process. This is mainly used to grant access to resources that are guarded by group permissions, such as Docker sockets, serial devices, or shared volumes with strict GID ownership.

## Host groups, and why they matter

On Linux hosts, files, sockets, and devices have owner and group IDs. When you bind-mount a host path or socket into a container, the container sees the same numeric UID/GID as the host. If the container process belongs to a matching group ID, it can access the resource without running as root.

## Common uses

- Allow a non-root user in the container to access a host-mounted path owned by a specific GID.
- Grant access to Unix sockets or devices that are group-protected.

## Example

```yaml
services:
  app:
    image: alpine:3.20
    user: "1000:1000"
    group_add:
      - "998" # Example GID for a shared volume group on the host
    volumes:
      - ./data:/data
    command: ["sh", "-c", "id && ls -la /data"]
```

## Example: add the host Docker group

If you mount the Docker socket, the container needs the Docker group GID from the host. First, find the GID on the host:

```bash
getent group docker
```

Example output:

```
docker:x:998:
```

Then add that GID in Compose:

```yaml
services:
  tooling:
    image: docker:27.1-cli
    user: "1000:1000"
    group_add:
      - "998" # GID from getent group docker
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: ["sh", "-c", "docker ps"]
```

## Notes and pitfalls

- `group_add` expects numeric GIDs or group names that exist inside the container. Using numeric GIDs is more portable.
- Group membership only affects permission checks; it does not change file ownership.
- Avoid using `group_add` as a workaround for incorrect file ownership. Prefer fixing ownership on the host or in a build step.

# extra_hosts

## What it does

`extra_hosts` adds static host-to-IP mappings to a container, similar to entries in `/etc/hosts`.

## Syntax

Use a list of strings in the format `"name:ip"`. Multiple entries are allowed. You can also use the special `host-gateway` keyword to map a name to the host gateway IP as resolved by Docker.

## Common uses

- Point a container to a specific IP for a hostname that cannot be resolved by DNS.
- Override a hostname in a controlled local environment for testing.

## Example

```yaml
services:
  api:
    image: curlimages/curl:8.11.1
    extra_hosts:
      - "db.local:10.10.0.25"
      - "legacy.service:192.168.1.50"
    command: ["sh", "-c", "getent hosts db.local && getent hosts legacy.service"]
```

## Example: use host-gateway

```yaml
services:
  api:
    image: curlimages/curl:8.11.1
    extra_hosts:
      - "host.internal:host-gateway"
    command: ["sh", "-c", "getent hosts host.internal"]
```

## Notes and pitfalls

- `extra_hosts` is static. If the target IP changes, containers need to be recreated to pick up new mappings.
- Use DNS or service discovery for dynamic environments. `extra_hosts` is best for small, fixed mappings.
- Entries apply only inside the container, not on the host or other containers.

# Quick reference

| Key | Purpose | Typical values | Scope |
| --- | --- | --- | --- |
| `user` | Set process UID and GID | `"1000:1000"`, `"appuser"` | Container process permissions |
| `group_add` | Add supplemental Linux groups | Numeric GIDs or group names | Container process permissions |
| `extra_hosts` | Static hostname mappings | `"name:ip"` strings | Container `/etc/hosts` |

# Troubleshooting

- `group_add` not working: verify the GID exists on the host and matches the permissions of the mounted path.
- `extra_hosts` not resolving: check `/etc/hosts` inside the container and recreate the service after edits.
- `user` issues: check for missing home directory or expected username if the app requires it.
