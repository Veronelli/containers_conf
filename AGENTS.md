# Project Guidelines

This repository holds composable container stacks. Each folder at the project root represents one container composition.

## Folder convention

Every top-level folder (except `.git`, `.opencode`, and `openspec`) is a self-contained container composition. A composition includes:

- A build description for the container image
- A service definition that describes how to run it
- A runtime configuration template (`.env.example`)
- Helper scripts to build and run

## Orchestration-agnostic naming

Use naming that works with **any** container runtime — Docker, Podman, Kubernetes, or others. No tool-specific names.

| Use this               | Not this              |
|------------------------|-----------------------|
| `Containerfile`        | `Dockerfile`          |
| `compose.yaml`         | `docker-compose.yml`  |
| `compose.yaml`         | `docker-compose.yaml` |

Helper scripts use the generic naming, never hardcoding a specific runtime:

| Do                                          | Don't                               |
|---------------------------------------------|-------------------------------------|
| Invoke via `compose.yaml`                   | Hardcode `docker compose`           |
| Document runtime-agnostic commands          | Write Docker-specific instructions  |

## Configuration via environment variables

- Every configurable value lives in environment variables.
- Provide an `.env.example` file as a documented template.
- The runtime `.env` file is never committed (add to `.gitignore`).
- Helper scripts load `.env` and export all variables so the compose file stays clean.

## Structure per composition

```
<service-name>/
├── Containerfile                     # OCI-compatible image build
├── compose.yaml                      # Service definition, env-driven
├── .env.example                      # Documented configuration template
├── .gitignore                        # Ignore .env, data/, logs
├── docker-entrypoint.sh              # Startup logic (use envsubst if templating)
├── run-compose.sh                    # Wrapper that loads .env and runs compose
├── provisioning/                     # Runtime-rendered config templates
│   ├── datasources/*.yaml.template
│   └── dashboards/*.yaml.template
├── dashboards/                       # Static dashboard definitions
└── README.md                         # Composition docs
```

## Security defaults

- Containers run as **non-root** users.
- Enable `no-new-privileges:true` in the compose definition.
- Define CPU and memory limits explicitly.
- Never hardcode secrets — use environment variables.

## Documentation per composition

Every folder includes a `README.md` covering:

- Purpose and architecture
- Prerequisites
- Quick-start steps
- Full environment variable table
- Notes on security and persistence
