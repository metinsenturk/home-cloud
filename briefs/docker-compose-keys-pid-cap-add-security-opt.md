---
title: Managing Container Security Context & Isolation
description: What these Compose service keys do, when to use them, and safe usage patterns.
created: 2026-02-18
updated: 2026-02-18
tags:
  - docker
  - docker-compose
  - containers
  - security
  - linux
category: DevOps
references:
  - https://docs.docker.com/compose/compose-file/05-services/
  - https://docs.docker.com/engine/reference/run/
  - https://man7.org/linux/man-pages/man7/capabilities.7.html
  - https://docs.docker.com/engine/security/seccomp/
  - https://docs.docker.com/engine/security/apparmor/
---

# Overview

Docker Compose service keys `pid`, `cap_add`, `security_opt`, and `privileged` control process namespaces and security boundaries. They are powerful and sometimes necessary for observability, debugging, or host integration, but they can also widen the container's security footprint. Use them deliberately, document why they are needed, and prefer the least-privilege option.

## Quick Reference

| Key | What it controls | Typical use case | Risk level |
| --- | --- | --- | --- |
| `pid` | Process ID namespace | Need to see host processes | Medium to high |
| `cap_add` | Linux capabilities granted to the container | Require extra kernel privileges | Medium to high |
| `security_opt` | Security profiles and labels (seccomp/AppArmor/SELinux) | Debugging, special syscalls, or profile tuning | Medium to very high |
| `privileged` | Broad access to host devices and kernel features | Low-level system tools or hardware access | Very high |

# `pid`

## What it is
`pid` defines which PID namespace the container uses. PID namespaces isolate process IDs between containers and the host. By default, a container runs in its own PID namespace, so it can only see its own processes.

## Common values
- `pid: "host"` shares the host PID namespace. The container can see host processes.
- `pid: "service:<service_name>"` shares the PID namespace with another service in the same Compose file.

## When to use it
- Process visibility for host monitoring tools.
- Debugging tools that need to inspect other processes.

## Example
```yaml
services:
  monitor:
    image: example/monitor:latest
    pid: "host"
```

## Notes
- `pid: "host"` is Linux-specific; behavior can differ on non-Linux platforms.
- Sharing PID namespaces increases visibility but does not automatically grant permissions to read other processes.

# `cap_add`

## What it is
`cap_add` adds Linux capabilities to the container. Linux capabilities split root privileges into fine-grained units. Containers run with a reduced set of capabilities by default.

## Common examples
- `SYS_PTRACE`: needed for debugging or inspecting other processes.
- `NET_ADMIN`: needed for advanced network configuration.

## When to use it
- Your workload needs specific kernel capabilities.
- You want to avoid `privileged: true` and grant only the required permissions.

## Example
```yaml
services:
  debugger:
    image: example/debugger:latest
    cap_add:
      - SYS_PTRACE
```

## Notes
- Capabilities are Linux-only; they are ignored or handled differently on other platforms.
- Prefer adding a single capability over using `privileged: true`.

# `security_opt`

## What it is
`security_opt` sets security-related options for the container runtime, such as seccomp profiles, AppArmor, or SELinux labels.

## Common options
- `seccomp=unconfined`: disables the default seccomp profile.
- `apparmor=unconfined`: disables AppArmor confinement.
- `label=type:container_runtime_t`: adjusts SELinux labels (Linux only).

## When to use it
- The application needs syscalls blocked by the default seccomp profile.
- You have a custom profile for tighter restrictions.
- Troubleshooting requires temporarily relaxing restrictions.

## Example
```yaml
services:
  special:
    image: example/special:latest
    security_opt:
      - seccomp=unconfined
```

## Notes
- Disabling seccomp or AppArmor can significantly reduce isolation. Use only when required.
- Prefer custom profiles over `unconfined` for production.

# `privileged`

## What it is
`privileged: true` gives a container broad access to the host, including device access and a large set of kernel capabilities. It effectively disables many of Docker's default isolation controls.

## When to use it
- Hardware or low-level system tooling that requires full device access.
- As a last resort when more targeted options cannot satisfy the requirement.

## Example
```yaml
services:
  hardware-tool:
    image: example/hardware-tool:latest
    privileged: true
```

## Notes
- `privileged` is much broader than using `cap_add` and `security_opt` and should be avoided unless strictly required.
- On Docker Desktop, behavior depends on the Linux VM boundary; privileges apply inside that VM, not the Windows or macOS host.

# Safe Usage Patterns

1. **Start with defaults** and only add what is required.
2. **Document why** a setting is needed and what breaks without it.
3. **Minimize scope**: prefer specific capabilities and custom profiles over `privileged`.
4. **Test on target OS**: Linux host behavior differs from Docker Desktop on Windows or macOS.

# Troubleshooting Tips

- If a tool cannot read process data, you may need both `pid: "host"` and `cap_add: ["SYS_PTRACE"]`.
- If an app crashes with a syscall error, check seccomp/AppArmor logs and consider a custom profile.
- If behavior differs on Docker Desktop, confirm the Linux VM layer is being used for namespaces and capabilities.
