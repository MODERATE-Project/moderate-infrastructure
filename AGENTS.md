# AGENTS.md

## Project Overview

Docker Compose deployment of the MODERATE Horizon Europe platform on a single Linux host.

## Conventions

- Use a single `compose.yaml` named `moderate` without `profiles` or templating.
- All services join the `moderate` default network for inter-container connectivity.
- One-shot jobs (like migrations) must be listed in `depends_on` with `condition: service_completed_successfully` in at least one service, or `docker compose up --wait` will fail when the job exits.
- Store persistent data in named volumes. Put configuration files for each service in `config/<service>/` and mount them read-only.
- Only use `.env` for variable interpolation; set variables per service under `environment:`. Never use `env_file: .env`.
- Add new variables to `.env.example`. `task init` fills empty `_PASSWORD` and `_SECRET` variables with 64 hex characters and empty `_FERNET_KEY` variables with a Fernet key. Any other empty variable must be set by hand, and `task check` fails until it is.
- `scripts/init.sh` generates secrets under `secrets/`, but never overwrites existing values.
- Store longer shell scripts in `scripts/`, especially if they use Go templates (like `docker compose ps --format '{{.Service}}'`), to avoid Task expanding braces.
