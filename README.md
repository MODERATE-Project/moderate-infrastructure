# MODERATE Infrastructure

Docker Compose deployment of the MODERATE platform on a single Linux x86_64 host.

> [!NOTE]
> The Terraform deployment on Google Cloud (GKE) that used to live here is archived in the [`gcp-gke-final` release](https://github.com/MODERATE-Project/moderate-infrastructure/releases/tag/gcp-gke-final).

## Requirements

- [Docker Engine](https://docs.docker.com/engine/install/) with the [Compose plugin](https://docs.docker.com/compose/install/linux/), v2.38 or newer
- [Task](https://taskfile.dev/docs/installation)
- Git, Bash and OpenSSL, installed through your distribution's package manager

Run the commands below on the Linux host with a user that can run `docker`.

Point these DNS names at the host, replacing `<domain>` with your domain:

- `www.<domain>`
- `<domain>` (redirects to `www.<domain>`)
- `keycloak.<domain>`
- `api.gw.<domain>`
- `s3.<domain>`
- `openmetadata.<domain>`
- `geoserver.<domain>`
- `docs.<domain>`

Open TCP ports 80 and 443 for HTTP redirects and HTTPS certificate issuance.

## Deploy from scratch

Clone the repository and initialize the configuration:

```console
git clone https://github.com/MODERATE-Project/moderate-infrastructure.git
cd moderate-infrastructure
task init
```

`task init` creates `.env`, generates passwords and the Fernet key, and writes the OpenMetadata JWT keypair to `secrets/`.

Generate two separate wallet mnemonics by running this command twice:

```console
docker run --rm --entrypoint gen-mnemonic ghcr.io/moderate-project/trust-service:sha-15f883c
```

Edit these three entries in `.env`:

```dotenv
DOMAIN=example.org
TRUST_MNEMONIC="<words from the first run>"
TRUST_KEY_STORAGE_MNEMONIC="<words from the second run>"
```

Use your base domain without `https://`, a path or the `www.` prefix. For each mnemonic, copy only the words after `Mnemonic:`. Keep the other generated values.

Check the configuration, start the stack and verify its containers:

```console
task check
task bootstrap
task smoke
```

Startup sets up databases, imports Keycloak settings, runs migrations, deploys contracts and starts the workflow sensors. No manual Keycloak steps are needed. `task bootstrap` waits for all services to be ready, and `task smoke` succeeds silently when everything is healthy.

Sign in to `https://www.<domain>` as `admin`, using `PLATFORM_ADMIN_PASSWORD` from `.env`. To administer Keycloak, open `https://keycloak.<domain>/admin/` and sign in as `admin` with the separate `KEYCLOAK_ADMIN_PASSWORD`.

## Connect the API to OpenMetadata

After the first start:

1. Sign in at `https://openmetadata.<domain>` as `admin`, using `PLATFORM_ADMIN_PASSWORD` from `.env`.
2. Open **Settings → Bots → ingestion-bot** and copy its JWT token.
3. Add `OPENMETADATA_BOT_TOKEN=<token>` to `.env`.
4. Run `task up` to apply the token to the API and workflows.

Until this step is complete, the API runs with its OpenMetadata integration disabled and OpenMetadata ingestion workflows fail.

## Workflows

Dagster handles background workflows. `dagster-code` runs jobs one at a time; `dagster-daemon` triggers them as needed. PostgreSQL stores state, and a shared volume holds logs and job outputs. The database sets up automatically on first launch.

Running `task up` starts three sensors: for user identities, object proofs, and matrix-profile requests. These restart if stopped in the UI. OpenMetadata ingestion and demo jobs are manual and need `OPENMETADATA_BOT_TOKEN`.

The Dagster UI is at `127.0.0.1:3000` with no login.

Only `dagster-code` can access `/var/run/docker.sock` (root permissions). The stack expects Docker at this path.

Before shutdown or backup, stop `dagster-daemon`, make sure runs are finished or cancelled in the UI, and no `matrix-profile-*` containers remain. Compose doesn't manage these job containers. If `dagster-code` is restarted mid-run, clean up any leftover containers and stale runs in the UI before resuming.

## Diagnose a failed deployment

`task check` lists empty variables and checks Compose configuration. `task smoke` lists missing, stopped or unhealthy services and failed initialization jobs. Inspect the containers and the logs of a reported service:

```console
docker compose ps --all
docker compose logs --tail=100 keycloak
```

Replace `keycloak` with any service you want to check. Jobs like `api-migrate`, `openmetadata-migrate`, `trust-contracts`, and `dagster-sensors` exit after finishing. Run `task smoke` before pruning these containers.

## Operations and configuration

Use `task up` to apply config changes and `task down` to stop containers (volumes are kept). Passwords and keys are not changed on re-initialization. PostgreSQL and Keycloak setup only run on a new database or realm; editing `.env` or the realm does not update existing Keycloak users or clients.

Run `task backup` to stop everything, save all volumes, `.env`, and `secrets/` into `backups/<timestamp>`, then restart. The Caddy volume is kept for HTTPS certificate reuse.

## Local trust chains

The trust service uses a [local-chain setup](https://github.com/MODERATE-Project/trust-service/tree/15f883c6a1add4f17041e44d2f8f734c86cb9527). `trust-iota` runs a private Stardust network; `trust-evm` uses Anvil with chain ID 1074. Both use versioned images and do not expose ports.

The local faucet funds IOTA wallets. Anvil provides two prefunded accounts: one for contract deployment, one for service transactions. These keys are local only; you don't need external funds. If your `.env` has `TRUST_L2_PRIVATE_KEY`, you can remove it since it’s unused.
