# Nginx Gateway

`nginx-gateway` is an HTTP reverse proxy that gives services on a shared container network one entry point. It selects a destination by the requested domain, including explicit subdomains, and applies an access policy independently to each virtual host.

## Architecture

- The gateway is the only service in this composition and exposes one configurable HTTP port.
- It joins an existing external network named by `NGINX_NETWORK_NAME`; published services must join that same network.
- At startup, `docker-entrypoint.sh` turns `NGINX_ROUTES` into temporary Nginx virtual-host configuration, validates it with `nginx -t`, and only then starts Nginx.
- Route configuration is ephemeral. The gateway does not keep application data or configuration state between container recreations.

TLS termination, wildcard domain matching, path-based routing, automatic service discovery, and identity-provider integration are not included in this composition. Place the gateway behind a TLS terminator when HTTPS is required.

## Prerequisites

- A container runtime and a Compose-compatible executable, selected by `CONTAINER_RUNTIME` and `CONTAINER_COMPOSE_COMMAND`.
- An existing network shared by the gateway and every service that it will publish.
- DNS records or local host-file entries that point each configured domain to the gateway host.

Create the shared network once with the runtime selected in `.env`:

```sh
${CONTAINER_RUNTIME} network create shared-services
```

Connect each destination service to that external network using its service name as the upstream host.

## Quick Start

1. Create the runtime configuration:

   ```sh
   cp .env.example .env
   ```

2. Set `CONTAINER_RUNTIME`, `CONTAINER_COMPOSE_COMMAND`, `NGINX_NETWORK_NAME`, and `NGINX_ROUTES` in `.env` for the services on the shared network.

3. Review the policies and set any required `NGINX_ROUTE_<ROUTE_ID>_ALLOWLIST` or `NGINX_ROUTE_<ROUTE_ID>_BASIC_AUTH` values.

4. Build and start the gateway:

   ```sh
   ./run-compose.sh up -d --build
   ```

5. Verify the generated configuration and service health:

   ```sh
   ./run-compose.sh ps
   ./run-compose.sh logs -f nginx-gateway
   ```

6. Stop it when required:

   ```sh
   ./run-compose.sh down
   ```

## Routes

`NGINX_ROUTES` is a newline-separated list. Every non-empty line uses exactly this format:

```text
domain|service:port|policy
```

For example:

```text
grafana.example.test|grafana:3000|public
admin.example.test|admin:8080|allowlist
reports.example.test|reports:8080|basic-auth
```

The gateway creates one virtual host for every full domain. Therefore `grafana.example.test` and `admin.example.test` are separate virtual subdomains with independent destinations and access policies. Wildcard domains such as `*.example.test` are deliberately unsupported.

For every domain, derive `ROUTE_ID` by uppercasing it, replacing `.` with `_D_`, and replacing `-` with `_`. Examples:

| Domain | `ROUTE_ID` |
|---|---|
| `admin.example.test` | `ADMIN_D_EXAMPLE_D_TEST` |
| `api-v2.example.test` | `API_H_V2_D_EXAMPLE_D_TEST` |

### Access Policies

| Policy | Additional variable | Behavior |
|---|---|---|
| `public` | None | Forwards all requests for the configured domain. |
| `allowlist` | `NGINX_ROUTE_<ROUTE_ID>_ALLOWLIST` | Allows only comma-separated IP addresses or CIDR networks, then returns HTTP 403 to other clients. |
| `basic-auth` | `NGINX_ROUTE_<ROUTE_ID>_BASIC_AUTH` | Requires a single `username:password-hash` entry compatible with Nginx basic authentication. |

Generate basic-auth password hashes with a trusted password utility outside the image and inject the complete `username:password-hash` value through the runtime's secret mechanism where available. Do not commit credentials to `.env.example` or version control.

## Adding A Service

1. Attach the service to `NGINX_NETWORK_NAME` as an external network.
2. Ensure its service name and port are reachable from that network.
3. Add `subdomain.example.test|service-name:port|policy` to `NGINX_ROUTES`.
4. Add the policy-specific environment variable when using `allowlist` or `basic-auth`.
5. Restart the gateway with `./run-compose.sh up -d` and confirm its logs show a successful Nginx configuration test.
6. Point the subdomain DNS record to the gateway host and remove the service's direct host port mapping only after testing the route.

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `CONTAINER_RUNTIME` | Runtime command used for documented network-management commands. | `docker` |
| `CONTAINER_COMPOSE_COMMAND` | Compose-compatible executable used by the wrapper. | `docker-compose` |
| `NGINX_BASE_IMAGE` | OCI base image used to build the gateway image. | `nginx:1.27-alpine` |
| `NGINX_IMAGE_NAME` | Local image name. | `nginx-gateway-local` |
| `NGINX_IMAGE_TAG` | Local image tag. | `1.0.0` |
| `NGINX_CONTAINER_NAME` | Container name. | `nginx-gateway` |
| `NGINX_HOSTNAME` | Container hostname. | `nginx-gateway` |
| `NGINX_RESTART_POLICY` | Container restart policy. | `unless-stopped` |
| `NGINX_BIND_HOST` | Host interface for the HTTP mapping. | `0.0.0.0` |
| `NGINX_BIND_PORT` | Host HTTP port. | `8080` |
| `NGINX_HTTP_PORT` | Non-root HTTP port inside the container. | `8080` |
| `NGINX_NETWORK_NAME` | Existing network shared with destination services. | `shared-services` |
| `NGINX_CPU_LIMIT` | CPU limit for the gateway. | `0.50` |
| `NGINX_MEMORY_LIMIT` | Memory limit for the gateway. | `128m` |
| `NGINX_ROUTES` | Newline-separated `domain|service:port|policy` routes. | Example routes only |
| `NGINX_ROUTE_<ROUTE_ID>_ALLOWLIST` | Comma-separated allowed addresses or CIDRs for an `allowlist` route. | Required by its policy |
| `NGINX_ROUTE_<ROUTE_ID>_BASIC_AUTH` | `username:password-hash` credentials for a `basic-auth` route. | Required by its policy |

## Security And Persistence

- The image runs as the non-root `nginx` user, listens on an unprivileged internal port, enables `no-new-privileges:true`, and uses a read-only root filesystem.
- Generated configuration and basic-auth files live under a temporary in-memory `/tmp` mount with restrictive permissions. They are removed when the container stops.
- Client IP allowlists are only reliable when this gateway receives client connections directly. If another proxy is in front of it, configure trusted proxy handling before relying on client-address rules.
- Nginx forwards `Host`, `X-Real-IP`, `X-Forwarded-For`, and `X-Forwarded-Proto` to the upstream service.
