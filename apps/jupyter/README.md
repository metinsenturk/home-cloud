# Jupyter Lab with SciPy Stack

A Jupyter Lab environment with comprehensive scientific computing tools including NumPy, SciPy, Matplotlib, and Pandas. Notebooks are persisted using a Docker volume.

## Services

- **jupyter**: Jupyter Lab server with the SciPy notebook stack, providing interactive computing and data analysis capabilities.

## Access

Open your browser and navigate to: **http://jupyter.localhost**

## Starting this App

**From the app folder:**
```bash
cd apps/jupyter
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

**From the root folder:**
```bash
make up-jupyter
```

## Configuration

- The Jupyter environment listens on port 8888 (internally routed via Traefik).
- Notebooks are stored in the volume `home_jupyter_data` at `/home/jovyan/work`.
- Token-based authentication is disabled by default for ease of access. Enable it by setting `JUPYTER_TOKEN` in the `.env` file.
- The environment runs as the `jovyan` user (standard Jupyter user).

## Environment Variables

| Variable Name | Source | Service | Default/Example Value | Description |
|---|---|---|---|---|
| `JUPYTER_SUBDOMAIN` | Local | jupyter | `yes` | Subdomain to run the app |
| `JUPYTER_ENABLE_LAB` | Local | jupyter | `yes` | Enable Jupyter Lab interface instead of classic notebook |
| `JUPYTER_TOKEN` | Local | jupyter | (empty) | Authentication token for Jupyter (leave empty to disable auth) |
| `TZ` | Global | jupyter | `UTC` | Timezone for the Jupyter container |

## Volumes & Networks

| Name | Type | Purpose |
|---|---|---|
| `home_jupyter_data` | Volume | Persistent storage for Jupyter notebooks and work files at `/home/jovyan/work` |
| `home_jupyter_network` | Network | Internal network for Jupyter services |
| `home_network` | Network | External bridge network for Traefik routing |

## Official Documentation

- [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io)
- [SciPy Notebook Stack](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-scipy-notebook)
- [Jupyter Lab Documentation](https://jupyterlab.readthedocs.io)
