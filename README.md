# MODERATE Infrastructure

Docker Compose deployment of the MODERATE platform on a single Linux host. Services are being added under [#12](https://github.com/MODERATE-Project/moderate-infrastructure/issues/12).

The Terraform deployment on Google Cloud (GKE) that used to live here is archived in the [`gcp-gke-final` release](https://github.com/MODERATE-Project/moderate-infrastructure/releases/tag/gcp-gke-final).

## Requirements

- Docker Engine with the Compose plugin
- [Task](https://taskfile.dev/)
- OpenSSL

## First run

```console
task init
```

This creates `.env` from `.env.example`, generates the passwords and the Fernet key, and writes the OpenMetadata JWT keypair to `secrets/`. Set the variables that are still empty in `.env` (the trust service credentials), then start the stack:

```console
task bootstrap
```
