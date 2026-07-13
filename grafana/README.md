# Grafana Docker Compose Stack

This directory contains a Grafana setup configured to use an existing **MariaDB** as both its internal database and as a queryable datasource. All configurable values are sourced from environment variables.

The goal is to maintain a single MariaDB instance shared across applications instead of creating one database per application.

## Architecture

- **Grafana** uses MariaDB as its internal database (users, dashboards, folders) via `GF_DATABASE_*` variables.
- **Grafana** provisions a MariaDB datasource to query the same shared database.
- No additional database engine is needed — one MariaDB serves both Grafana and your applications.

## Files

- `Containerfile`: extends `grafana/grafana:11.5.0`, installs runtime helpers, and copies provisioning templates into the image.
- `compose.yaml`: defines the Grafana service, healthcheck, network, and resource limits.
- `.env.example`: placeholder configuration template.
- `.env`: local runtime configuration file with placeholder values that must be replaced before production use.
- `docker-entrypoint.sh`: renders provisioning templates via `envsubst` at startup and sets `GF_DATABASE_*` environment variables.
- `run-compose.sh`: helper wrapper that always loads `.env`.
- `provisioning/datasources/mariadb.yaml.template`: template for the MariaDB datasource, rendered at runtime.
- `provisioning/dashboards/dashboards.yaml.template`: template for the dashboard provider, rendered at runtime.
- `dashboards/`: sample dashboards (e.g. MariaDB Overview).

## Prerequisites

- A running MariaDB instance accessible from the container.
- A database user with `CREATE` privileges on the `grafana` database (Grafana will create its schema on first run).

## Quick start

1. Review and update `.env` with your MariaDB connection details.

2. Create the Grafana database in your MariaDB:

   ```sql
   CREATE DATABASE IF NOT EXISTS grafana CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   GRANT ALL PRIVILEGES ON grafana.* TO 'grafana'@'%' IDENTIFIED BY 'your-password';
   FLUSH PRIVILEGES;
   ```

3. Build and start the stack:

   ```sh
   ./run-compose.sh up -d --build
   ```

4. Check service status:

   ```sh
   ./run-compose.sh ps
   ./run-compose.sh logs -f grafana
   ```

5. Access Grafana at `http://localhost:3000` and log in with the admin credentials from `.env`.

6. Stop the stack:

   ```sh
   ./run-compose.sh down
   ```

## Environment variables

| Variable | Description | Default |
|---|---|---|
| `GRAFANA_IMAGE_TAG` | Grafana image version | `11.5.0` |
| `GRAFANA_BIND_PORT` | Host port mapping | `3000` |
| `GRAFANA_ADMIN_USER` | Initial admin user | `admin` |
| `GRAFANA_ADMIN_PASSWORD` | Initial admin password | `change-me-password` |
| `GRAFANA_DATABASE_TYPE` | Backend database type | `mysql` |
| `GRAFANA_DATABASE_HOST` | MariaDB host:port | `mariadb:3306` |
| `GRAFANA_DATABASE_NAME` | Grafana database name | `grafana` |
| `GRAFANA_DATABASE_USER` | Grafana database user | `grafana` |
| `GRAFANA_DATABASE_PASSWORD` | Grafana database password | `change-me-password` |
| `GRAFANA_DATASOURCE_MARIADB_HOST` | Datasource host:port | `mariadb:3306` |
| `GRAFANA_DATASOURCE_MARIADB_DATABASE` | Datasource database name | `puma_core` |
| `GRAFANA_DATASOURCE_MARIADB_USER` | Datasource user | `root` |
| `GRAFANA_DATASOURCE_MARIADB_PASSWORD` | Datasource password | `change-me-password` |

## Container orchestration agnosticism

The compose file follows the same conventions as the `chromadb/` sibling. All values are parameterized through environment variables, making it straightforward to adapt to:

- **Docker Compose** (current)
- **Kubernetes** (via `envFrom` / ConfigMap)
- **Docker Swarm**
- **Nomad**
- Any other orchestrator

Simply load the `.env` file and map the variables to the platform's native configuration mechanism.

## Notes

- Grafana runs as the `grafana` user (non-root) for security.
- The container runs with `no-new-privileges:true`.
- CPU and memory limits default to `GRAFANA_CPU_LIMIT=1.00` and `GRAFANA_MEMORY_LIMIT=512m`.
- Provisioning is done via templates (`*.yaml.template`) rendered by `envsubst` at container startup, so all configuration stays in `.env`.
- Persistent Grafana data (plugins, alerting state) is stored in a named Docker volume `grafana_data`.
- JSON-like values remain shell-safe in `.env` by using quoted strings with escaped double quotes.
