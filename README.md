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

## Manual DNS update

Please note that the deployment process for this project involves a manual step: you will need to add an A DNS record for each Ingress resource, pointing to the public IP address of the NGINX controller.

To do this, you will need to obtain the public IP address of the NGINX controller. First, you may need to get the GKE cluster credentials for your local terminal:

```
gcloud container clusters get-credentials gke-cluster --region <cluster_region> --project <cluster_project_id>
```

This will configure `kubectl` to access the cluster. Now you can get the public IP of the NGINX controller with the following command:

```
kubectl get service/ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```