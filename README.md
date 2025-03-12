# MODERATE Cloud Infrastructure

This repository contains the computing infrastructure for the MODERATE Horizon Europe project. It is based on [Terraform](https://www.terraform.io/). Terraform follows the Infrastructure-as-Code (IaC) approach, allowing developers to define cloud resources through code in a reusable and reproducible way.

## Credentials

To use both **Google Cloud** and **Terraform Cloud** services, you must provide credentials. Specifically, you first need to obtain user access credentials for _Application Default Credentials_ (ADC) using the [gcloud CLI](https://cloud.google.com/sdk/gcloud).

```
gcloud auth application-default login
```

Additionally, you must log in to Terraform Cloud using the [Terraform CLI](https://developer.hashicorp.com/terraform/downloads):

```
terraform login
```

## Usage

To deploy the infrastructure, you may run the following command:

```console
task apply-prod
```

This will do the following:

* Initialize the Terraform workspace.
* Apply the Terraform configuration to the cloud provider.
* Fetch the credentials for the Kubernetes cluster and configure the local `kubectl` client.
* Update the DNS records to point to the Kubernetes cluster.

### About the MODERATE CLI image

The [MODERATE CLI](./cli) is a utility to interact programmatically with the MODERATE infrastructure. Its main objective is to contain the logic necessary to automatically initialize some services that require configuration that cannot be achieved through Terraform alone. For example, the MODERATE CLI is used to create the initial realm in Keycloak.

The image needs to be built locally and pushed to a public registry for the Kubernetes Jobs that are defined in the Terraform configuration to be able to pull it. To build and push the image, run the following command:

```console
task push-cli-image
```

By default the image is published in Docker Hub under the [`agmangas/moderate-cli`](https://hub.docker.com/r/agmangas/moderate-cli) repository. However, this can be configured in the `Taskfile.yml` file.

### Manual steps

#### Updating the DNS records

The DNS records for the `moderate.cloud` domain are managed by Google's Cloud DNS. It is necessary to manually update these records to point to the newly created NGINX Ingress load balancer. This is achieved by running the [`update-dns.sh`](scripts/update-dns.sh) script.

> Please note that when using the `task apply-prod` task this will be automatically done for you.

#### Configuring the OpenMetadata JWT tokens

> [!IMPORTANT]
> To enable first-time login to OpenMetadata, you must first create a user in Keycloak whose email matches the `initialAdmins@principalDomain` configuration in OpenMetadata.

There are two OpenMetadata tokens that need to be configured:

* One for the Dagster assets that run the metadata workflows.
* Another for the Platform's API.

These tokens can only be generated manually in the OpenMetadata web UI. To do so, access the *Settings > Bots* section in the OpenMetadata UI.

Then, add the new tokens to the `open_metadata_token` and `open_metadata_api_token` variables in the `variables.auto.tfvars` file of the `gcp_prod` Terraform module. Re-apply the Terraform configuration to update the Kubernetes secrets.

#### Edit authentication flows in Keycloak

Some of the applications depend on Keycloak to restrict access to users with a specific role. This is not done automatically, due to this particular interaction not being supported in the utility package that is used to manage Keycloak. Therefore, it is necessary to edit the authentication flows in Keycloak to include a condition that checks for the appropriate role.

#### Assigning roles

Note that some services in MODERATE may require specific roles. It's not enough for a user to exist in the Keycloak realm; they must also have the appropriate roles.

> [!IMPORTANT]
> Users without the *API access* or *API admin* roles will be able to log into the Web UI, but they won't be able to use it, as all requests will fail.
