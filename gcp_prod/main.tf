terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.53.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

terraform {
  cloud {
    organization = "moderate"

    workspaces {
      name = "prod-gcp"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone_default
}

module "gke_cluster" {
  source               = "../modules/gke_cluster"
  project_id           = var.project_id
  region               = var.region
  zones                = var.zones
  registry_project_ids = [var.project_id_common]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = module.gke_cluster.kubernetes_host
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = module.gke_cluster.kubernetes_cluster_ca_cert
}

provider "kubectl" {
  host                   = module.gke_cluster.kubernetes_host
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = module.gke_cluster.kubernetes_cluster_ca_cert
}

module "docs_app" {
  source = "../modules/docs_app"
}
