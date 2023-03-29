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

data "google_client_config" "default" {}

data "google_client_openid_userinfo" "provider_identity" {}

module "gke_cluster" {
  source               = "../modules/gke_cluster"
  project_id           = local.gke_project_id
  region               = var.region
  zones                = var.zones
  registry_project_ids = [var.project_id_common]
  # This should be true when in production
  regional = false
  # A cheaper shared-core machine type for the first stages of the project
  nodes_machine_type = "e2-medium"
}

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
  depends_on                  = [module.nginx_controller_gke]
  source                      = "../modules/cert_manager"
  cluster_admin_account       = local.cluster_admin_email
  kube_host                   = module.gke_cluster.kubernetes_host
  kube_cluster_ca_certificate = module.gke_cluster.kubernetes_cluster_ca_cert

  providers = {
    kubectl = kubectl
  }
}

module "docs_app" {
  depends_on          = [module.nginx_controller_gke]
  source              = "../modules/docs_app"
  domain              = var.domain_docs
  cert_manager_issuer = module.cert_manager.cluster_issuer_prod_name
}

module "postgres_cloud_sql" {
  source             = "../modules/postgres_cloud_sql"
  project_id         = var.project_id
  region             = var.region
  cluster_network_id = module.gke_cluster.cluster_network_id
}

module "postgres_cloud_sql_proxy" {
  depends_on                = [module.gke_cluster]
  source                    = "../modules/postgres_cloud_sql_proxy"
  project_id                = var.project_id
  cloud_sql_connection_name = module.postgres_cloud_sql.sql_instance_connection_name
}

module "yatai" {
  depends_on                        = [module.cert_manager]
  source                            = "../modules/yatai"
  project_id                        = var.project_id
  region                            = var.region
  google_sql_database_instance_name = module.postgres_cloud_sql.sql_instance_name
  postgres_host                     = module.postgres_cloud_sql_proxy.cloud_sql_proxy_service
  cert_manager_issuer               = module.cert_manager.cluster_issuer_prod_name
  domain                            = var.domain_yatai
  docker_registry_server            = var.docker_registry_server
  docker_registry_username          = var.docker_registry_username
  docker_registry_password          = var.docker_registry_password
  docker_bento_repository_name      = "${var.project_id_common}/${var.artifact_registry_repository_name}/bentos"
}

module "keycloak" {
  depends_on                         = [module.cert_manager]
  source                             = "../modules/keycloak"
  project_id                         = var.project_id
  domain                             = var.domain_keycloak
  cert_manager_issuer                = module.cert_manager.cluster_issuer_prod_name
  cloud_sql_instance_name            = module.postgres_cloud_sql.sql_instance_name
  cloud_sql_instance_connection_name = module.postgres_cloud_sql.sql_instance_connection_name
}

module "apisix" {
  depends_on          = [module.cert_manager]
  source              = "../modules/apisix"
  domain              = "api.moderate.cloud"
  cert_manager_issuer = module.cert_manager.cluster_issuer_prod_name
}
