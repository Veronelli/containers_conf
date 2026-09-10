## 1. Composition Foundation

- [x] 1.1 Create the `nginx-gateway` composition directory with `.gitignore`, `.env.example`, `Containerfile`, `compose.yaml`, `docker-entrypoint.sh`, `run-compose.sh`, and `README.md`, and verify every required composition file is present.
- [x] 1.2 Build an OCI-compatible Nginx image that includes only the configuration-generation and validation tools needed at runtime, creates writable runtime directories, and runs Nginx as a non-root user; verify the built image reports a non-root effective user.
- [x] 1.3 Define the environment-driven service with configurable image, hostname, bind address, HTTP port, restart policy, CPU and memory limits, external network, health check, and `no-new-privileges:true`; verify `run-compose.sh config` resolves the service using a copied `.env.example`.
- [x] 1.4 Implement the runtime-agnostic composition wrapper to load and export `.env` before delegating to the selected compose command; verify it fails clearly when `.env` is absent and forwards `config` successfully when present.

## 2. Gateway Configuration

- [x] 2.1 Implement entrypoint parsing and validation for the multiline `NGINX_ROUTES` format, requiring a valid domain, `service:port` destination, and supported access policy for every route; verify invalid entries terminate before Nginx starts with an identifying error.
- [x] 2.2 Generate a default Nginx virtual host that rejects unmatched `Host` headers and one reverse-proxy virtual host per configured route with forwarded host, scheme, and client-address headers; verify `nginx -t` succeeds for a public sample route.
- [x] 2.3 Generate `allowlist` route configuration from its declared permitted IP networks and deny all other clients; verify the generated server block contains the expected allow and deny directives.
- [x] 2.4 Generate restricted credential files and Nginx authentication configuration for `basic-auth` routes from environment-provided secrets; verify a route with valid credentials passes Nginx configuration validation and generated credential files are not world-readable.

## 3. Documentation And Validation

- [x] 3.1 Document prerequisites, quick start, shared-network setup, route syntax, public/allowlist/basic-auth policies, adding a service, security notes, persistence behavior, and every environment variable; verify the README matches `.env.example` variable names.
- [x] 3.2 Validate the completed OpenSpec change with `openspec validate add-nginx-gateway --strict` and correct all reported issues.
- [x] 3.3 Build the image and perform a local smoke test with a reachable sample upstream, a matching domain, and an unmatched domain; verify matching traffic reaches the upstream while the unmatched request returns a client error.
