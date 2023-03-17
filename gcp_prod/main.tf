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

locals {
  gke_project_id      = var.project_id
  cluster_admin_email = data.google_client_openid_userinfo.provider_identity.email
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone_default
}

module "gke_cluster" {
  source               = "../modules/gke_cluster"
  project_id           = local.gke_project_id
  region               = var.region
  zones                = var.zones
  registry_project_ids = [var.project_id_common]
}

data "google_client_config" "default" {}

data "google_client_openid_userinfo" "provider_identity" {}

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

provider "helm" {
  kubernetes {
    host                   = module.gke_cluster.kubernetes_host
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = module.gke_cluster.kubernetes_cluster_ca_cert
  }
}

module "nginx_controller_gke" {
  source                     = "../modules/nginx_controller_gke"
  cluster_admin_account      = local.cluster_admin_email
  gke_network_name           = module.gke_cluster.cluster_network_name
  gke_master_ipv4_cidr_block = module.gke_cluster.master_ipv4_cidr_block
}

module "cert_manager" {
  source                 = "../modules/cert_manager"
  cluster_admin_account  = local.cluster_admin_email
  gke_cluster_project_id = local.gke_project_id
  cloud_dns_project_id   = var.project_id_common
}

module "docs_app" {
  source = "../modules/docs_app"
}
