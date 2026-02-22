# Coder Home Lab: Traefik & Docker Setup

This documentation covers the deployment of Coder on a Windows host using Docker Desktop, managed via Docker Compose and routed through a Traefik reverse proxy.

## 1. Host Prerequisites (Windows)

Because Coder and VS Code Desktop rely on local domain resolution, you must map your local domain to your loopback address.

### Update Hosts File

1. Open **Notepad** as Administrator.
2. Edit `C:\Windows\System32\drivers\etc\hosts`.
3. Add the following entries:
```text
127.0.0.1  coder.localhost
127.0.0.1  code-server.coder.localhost

```

Verify that coder.localhost domain is updated in the hosts file by opening a terminal on the host and ping it.

```
ping coder.localhost
```


### Pre-pull Workspace Image

To avoid Docker Hub rate limits and "Denied" errors during workspace creation, manually pull the base image to your host:

```powershell
docker pull codercom/enterprise-base:ubuntu

```

---

## 2. Infrastructure (Docker Compose)

The Coder service must have access to the Docker socket and be on the same network as Traefik.

### Permissions

* **Option A (Simpler):** Run the Coder container with `user: root`.
* **Option B (Secure):** Use `group_add` with the GID of the docker group (found via `getent group docker | cut -d: -f3` in WSL).

### Traefik Labels

To allow VS Code Desktop and subdomains to work, use a Regexp rule in your labels:

```yaml
labels:
  - "traefik.http.routers.coder.rule=Host(`coder.localhost`) || HostRegexp(`{subdomain:[a-z0-9-]+}.coder.localhost`)"

```

### The "Host Gateway" Loopback

In the `docker-compose.yaml`, the `coder` service requires an `extra_hosts` mapping to resolve its own external domain.

```yaml
extra_hosts:
  - "coder.localhost:host-gateway"

```

#### Why this is required:

* **The Container Bubble**: By default, a container thinks `localhost` refers only to itself. It has no internal record of what `coder.localhost` is.
* **Routing to Traefik**: `host-gateway` is a special Docker keyword that points to the IP address of your Windows host.
* **The Handshake**: This mapping tells the Coder container: "If you need to reach `coder.localhost`, go out to the Windows Host." Traefik (listening on the host) then receives the request and routes it back into the Coder container correctly.
* **CLI & API Validation**: This is essential for the Coder CLI and the dashboard to validate the `CODER_ACCESS_URL` during the initial "login" and handshake phases.

---

## 3. Template Configuration (`main.tf`)

The Coder template requires specific tweaks to allow containers to "phone home" to the Coder server through the internal Docker network.

### Networking & Entrypoint

Inside the `resource "docker_container" "workspace"` block:

1. **Join the Network:** Ensure the workspace is on the same network as the Coder service.
```hcl
network_mode = "home_network"

```


2. **Internal DNS Routing:** Replace the external URL with the internal Docker service name to bypass Traefik for agent communication.
```hcl
entrypoint = ["sh", "-c", replace(coder_agent.main.init_script, "http://coder.localhost", "http://coder:3000")]

```

---

## 4. Environment Variables Reference

Key variables used in the `.env` file:

| Variable | Value | Purpose |
| --- | --- | --- |
| `CODER_ACCESS_URL` | `http://coder.localhost` | External URL for browser access. |
| `CODER_TLS_INSECURE_SKIP_VERIFY` | `true` | Prevents agent failure on internal HTTP/Self-signed traffic. |
| `CODER_HTTP_ADDRESS` | `0.0.0.0:3000` | Internal listening port. |

---

## 5. Troubleshooting

* **Agent "Waiting":** Check `docker logs <workspace_container_name>`. If you see "connection refused," verify the `replace()` function in `main.tf` points to the correct service name.
* **VS Code Desktop ENOTFOUND:** Ensure the Windows `hosts` file entry for `coder.localhost` is correct and you can `ping coder.localhost` from PowerShell.
* **Command Not Found (sudo/curl):** Use the `codercom/enterprise-base:ubuntu` image as it includes these tools by default.

---

## Final Documentation Checklist

Before you close your notes, ensure your directory structure looks like this for easy recovery:

* `.env` (Contains your tokens and URLs)
* `docker-compose.yaml` (With the `extra_hosts` and `networks`)
* `main.tf` (With the `replace()` entrypoint and `network_mode`)
* `C:\Windows\System32\drivers\etc\hosts` (Updated with `127.0.0.1 coder.localhost`)

