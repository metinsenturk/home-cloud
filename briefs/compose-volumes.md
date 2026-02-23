---
title: Docker Compose Volume Definitions
description: Define Docker Compose volumes using short/long syntax, shared volumes with subpaths, and volume key meanings
created: 2026-02-22
updated: 2026-02-22
tags:
  - docker
  - compose
  - volumes
  - storage
category: Containers
---

# Overview
Docker Compose lets services mount persistent volumes using either a short string syntax or a full mapping syntax. The long syntax is required for advanced options like `nocopy` and `subpath`.

# Short syntax
Short syntax is `source:target[:mode]`.

```yaml
services:
  app:
    image: example/app
    volumes:
      - app-data:/var/lib/app
      - ./cache:/var/cache/app:ro

volumes:
  app-data:
```

- `app-data` is a named volume defined at the top level.
- `./cache` is a bind mount from the host path.
- `:ro` sets the mount to read-only.

# Long syntax
Long syntax makes each field explicit and supports more options.

```yaml
services:
  app:
    image: example/app
    volumes:
      - type: volume
        source: app-data
        target: /var/lib/app
        volume:
          nocopy: true
      - type: bind
        source: ./cache
        target: /var/cache/app
        read_only: true

volumes:
  app-data:
```

# Sharing a volume with subpaths
You can mount different subdirectories of the same named volume into multiple services. This keeps data isolated while still sharing a single volume.

```yaml
services:
  api:
    image: example/api
    volumes:
      - type: volume
        source: shared-data
        target: /data/api
        subpath: api
  worker:
    image: example/worker
    volumes:
      - type: volume
        source: shared-data
        target: /data/worker
        subpath: worker

volumes:
  shared-data:
```

Notes:
- `subpath` must exist inside the volume for the mount to succeed.
- `subpath` is only supported for `type: volume` mounts.

# Mount fields reference
Common long-syntax fields under a service `volumes` entry:

| Field | Meaning | Applies to |
| --- | --- | --- |
| `type` | Mount type: `volume`, `bind`, or `tmpfs` | All mounts |
| `source` | Volume name or host path | `volume`, `bind` |
| `target` | Container mount path | All mounts |
| `read_only` | Read-only mount when `true` | All mounts |
| `subpath` | Subdirectory within a named volume to mount | `volume` |
| `volume.nocopy` | Do not copy pre-existing container data into a new volume | `volume` |

# Top-level volume keys
Top-level `volumes` entries define named volumes used by services.

```yaml
volumes:
  app-data:
    name: app-data
    driver: local
    driver_opts:
      o: bind
      type: none
      device: /srv/app-data
    external: false
    labels:
      com.example.purpose: app-storage
```

| Key | Meaning |
| --- | --- |
| `name` | Explicit volume name (defaults to project-scoped name) |
| `driver` | Volume driver (default `local`) |
| `driver_opts` | Driver-specific options |
| `external` | Use an existing volume managed outside Compose |
| `labels` | Metadata labels applied to the volume |

# Tips
- Use short syntax for simple mounts and long syntax when you need `nocopy`, `subpath`, or `read_only` clarity.
- Prefer named volumes for persistent data and bind mounts for local development files.
- Keep volume names stable when data should survive container recreation.
