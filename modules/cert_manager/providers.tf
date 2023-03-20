terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

data "google_client_config" "default" {}

provider "kubectl" {
  host                   = var.kube_host
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = var.kube_cluster_ca_certificate
  load_config_file       = false
}
