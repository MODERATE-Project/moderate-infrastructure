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