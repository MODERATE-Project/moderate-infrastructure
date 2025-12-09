# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the cloud infrastructure repository for the MODERATE Horizon Europe project, using Terraform for Infrastructure-as-Code (IaC) on Google Cloud Platform (GCP).

## Common Commands

All commands are run via [Task](https://taskfile.dev/) (see `Taskfile.yml`):

```bash
# Deploy full production infrastructure
task apply-prod

# Destroy production infrastructure
task destroy-prod

# Get kubectl credentials for GKE cluster
task get-credentials

# Update DNS records to point to cluster load balancer
task update-dns

# Build and push MODERATE CLI image to Docker Hub
task push-cli-image

# Port-forward Dagster UI to localhost:8181
task port-forward-dagster-ui

# Load SQL dump into Cloud SQL (requires env vars)
task load-cloud-sql-dump
```

### Direct Terraform Commands (in `gcp_prod/`)

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## Architecture

### Terraform Workspaces

The infrastructure uses Terraform Cloud with two workspaces in the "moderate" organization:

- `prod-gcp` (in `gcp_prod/`) - Main production infrastructure
- `common-gcp` (in `gcp_common/`) - Shared resources like artifact registry

### Module Structure

Custom Terraform modules in `modules/`:

| Module                     | Purpose                                      |
| -------------------------- | -------------------------------------------- |
| `gke_cluster`              | GKE cluster with VPC, node pools, and backup |
| `nginx_controller_gke`     | NGINX Ingress Controller                     |
| `cert_manager`             | TLS certificates with Let's Encrypt          |
| `postgres_cloud_sql`       | Cloud SQL PostgreSQL instance                |
| `postgres_cloud_sql_proxy` | Cloud SQL Auth Proxy in K8s                  |
| `keycloak`                 | Identity management                          |
| `keycloak_init`            | Keycloak realm/client configuration          |
| `moderate_api`             | Platform API with S3 storage                 |
| `apisix`                   | API Gateway with Keycloak auth               |
| `open_metadata`            | Data catalog                                 |
| `dagster`                  | Data orchestration                           |
| `yatai`                    | ML model deployment (BentoML)                |
| `mongo`                    | MongoDB for Trust Services                   |
| `rabbit`                   | RabbitMQ message broker                      |
| `trust_services`           | Trust/verification services                  |
| `geoserver`                | Geographic data server                       |
| `docs_app`                 | Documentation site                           |
| `dev_compute_instance`     | Development VM                               |

### Service Dependencies Flow

```
gke_cluster
    └── nginx_controller_gke
        └── cert_manager
            ├── keycloak → keycloak_init
            ├── open_metadata
            ├── yatai
            ├── apisix (API gateway)
            ├── dagster
            └── other services...
    └── postgres_cloud_sql → postgres_cloud_sql_proxy
```

### MODERATE CLI (`cli/`)

Python CLI tool (Poetry-managed) used by Kubernetes Jobs for service initialization (e.g., Keycloak realm creation). The image is published to `agmangas/moderate-cli` on Docker Hub.

```bash
# In cli/ directory
poetry install
poetry run moderatecli --help
```

## Required Authentication

Before running Terraform:

```bash
# GCP Application Default Credentials
gcloud auth application-default login

# Terraform Cloud login
terraform login
```

## Environment Configuration

- `.env.local` - Contains GCP project IDs and region (loaded by Taskfile)
- `gcp_prod/variables.auto.tfvars` - Terraform variable values including secrets
- Domain: `moderate.cloud` with subdomains for each service

## Key Provider Configuration

The `gcp_prod/main.tf` configures providers for:

- `google` - GCP resources
- `kubernetes` - K8s resources via GKE
- `kubectl` - Raw K8s manifests
- `helm` - Helm chart deployments
