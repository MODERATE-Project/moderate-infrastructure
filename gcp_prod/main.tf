terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.25.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
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

resource "google_project_service" "gcp_services" {
  for_each                   = toset(var.project_gcp_service_list)
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

module "gke_cluster" {
  source               = "../modules/gke_cluster"
  project_id           = local.gke_project_id
  region               = var.region
  zones                = var.zones
  registry_project_ids = [var.project_id_common]
  enable_backup        = true
  nodes_min_count      = var.nodes_min_count
  nodes_max_count      = var.nodes_max_count
  # ToDo: This should be true when in production
  regional = false
  # ToDo: This is set to 0 to enable immediate destruction during development
  backup_delete_lock_days = 0
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
  # Disable loading the local kubeconfig file. This is necessary because of this error:
  # Error: failed to create kubernetes rest client for read of resource: 
  # Get "http://localhost/api?timeout=32s": dial tcp [::1]:80: connect: connection refused
  load_config_file = false
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
  depends_on                 = [module.nginx_controller_gke]
  source                     = "../modules/cert_manager"
  cluster_admin_account      = local.cluster_admin_email
  use_dns01_google_cloud_dns = true
  project_id_cloud_dns       = var.project_id_common

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

module "keycloak_init" {
  source                 = "../modules/keycloak_init"
  keycloak_admin_user    = module.keycloak.keycloak_admin_user
  keycloak_admin_pass    = module.keycloak.keycloak_admin_pass
  keycloak_url           = "http://${module.keycloak.keycloak_service_host_port}"
  open_metadata_root_url = "https://${var.domain_open_metadata}"
  platform_ui_url        = "https://${var.domain_platform_ui}"
}

module "geoserver" {
  depends_on          = [module.cert_manager]
  source              = "../modules/geoserver"
  domain              = var.domain_geoserver
  cert_manager_issuer = module.cert_manager.cluster_issuer_prod_name
}

module "open_metadata" {
  depends_on                       = [module.cert_manager]
  source                           = "../modules/open_metadata"
  authorizer_principal_domain      = var.base_domain
  keycloak_url                     = "https://${var.domain_keycloak}"
  keycloak_realm                   = module.keycloak_init.moderate_realm_name
  open_metadata_keycloak_client_id = module.keycloak_init.open_metadata_client_id
  cloud_sql_instance_name          = module.postgres_cloud_sql.sql_instance_name
  postgres_host                    = module.postgres_cloud_sql_proxy.cloud_sql_proxy_service
  ingress_enabled                  = true
  open_metadata_domain             = var.domain_open_metadata
  cert_manager_issuer              = module.cert_manager.cluster_issuer_prod_name
}

module "mongo" {
  depends_on = [module.cert_manager]
  source     = "../modules/mongo"
}

module "rabbit" {
  depends_on = [module.cert_manager]
  source     = "../modules/rabbit"
}

module "trust" {
  depends_on     = [module.nginx_controller_gke]
  source         = "../modules/trust_services"
  mongo_endpoint = "${module.mongo.mongo_internal_host}:${module.mongo.mongo_internal_port}"
  mongo_username = module.mongo.mongo_admin_user
  mongo_password = module.mongo.mongo_admin_pass
  l2_private_key = var.trust_l2_private_key
}

module "api" {
  depends_on                         = [module.nginx_controller_gke]
  source                             = "../modules/moderate_api"
  project_id                         = var.project_id
  region                             = var.region
  cloud_sql_instance_name            = module.postgres_cloud_sql.sql_instance_name
  cloud_sql_instance_connection_name = module.postgres_cloud_sql.sql_instance_connection_name
  trust_service_endpoint_url         = module.trust.trust_internal_url
  domain_ui                          = var.domain_platform_ui
  cert_manager_issuer                = module.cert_manager.cluster_issuer_prod_name
  open_metadata_endpoint_url         = "http://${module.open_metadata.open_metadata_service_host_port}"
  open_metadata_bearer_token         = var.open_metadata_api_token
  postgres_host                      = module.postgres_cloud_sql_proxy.cloud_sql_proxy_service
  rabbit_router_url                  = module.rabbit.rabbit_private_url
}

module "apisix" {
  depends_on                        = [module.cert_manager]
  source                            = "../modules/apisix"
  base_domain                       = var.base_domain
  cert_manager_issuer               = module.cert_manager.cluster_issuer_prod_name
  yatai_proxy_node                  = module.yatai.proxy_service_host_port
  moderate_api_node                 = module.api.api_service_host_port
  keycloak_realm                    = module.keycloak_init.moderate_realm_name
  keycloak_client_id                = module.keycloak_init.apisix_client_id
  keycloak_client_secret            = module.keycloak_init.apisix_client_secret
  keycloak_permissions_yatai        = module.keycloak_init.apisix_client_resource_yatai
  keycloak_permissions_moderate_api = module.keycloak_init.apisix_client_resource_moderate_api
  cors_allow_origins                = ["https://${var.domain_platform_ui}"]
}

module "dagster" {
  depends_on                 = [module.cert_manager]
  source                     = "../modules/dagster"
  ingress_enabled            = false
  domain                     = var.domain_dagster
  cloud_sql_instance_name    = module.postgres_cloud_sql.sql_instance_name
  postgres_host              = module.postgres_cloud_sql_proxy.cloud_sql_proxy_service
  keycloak_admin_user        = module.keycloak.keycloak_admin_user
  keycloak_admin_pass        = module.keycloak.keycloak_admin_pass
  keycloak_url               = "http://${module.keycloak.keycloak_service_host_port}"
  cert_manager_issuer        = module.cert_manager.cluster_issuer_prod_name
  open_metadata_host         = "http://${module.open_metadata.open_metadata_service_host}"
  open_metadata_port         = module.open_metadata.open_metadata_service_port
  open_metadata_token        = var.open_metadata_token
  platform_api_username      = module.keycloak_init.platform_api_username
  platform_api_password      = module.keycloak_init.platform_api_password
  platform_api_url           = module.apisix.public_moderate_api_url
  s3_access_key              = module.api.api_s3_access_key
  s3_secret_key              = module.api.api_s3_secret_key
  s3_bucket_name             = module.api.api_s3_bucket_name
  s3_endpoint_url            = module.api.api_s3_endpoint_url
  s3_region                  = module.api.api_s3_region
  s3_job_outputs_bucket_name = module.api.outputs_s3_bucket_name
  rabbit_router_url          = module.rabbit.rabbit_private_url
}

module "tool_lec" {
  depends_on          = [module.cert_manager]
  source              = "../modules/tool_lec"
  domain              = var.domain_tool_lec
  cert_manager_issuer = module.cert_manager.cluster_issuer_prod_name
  geoserver_url       = "http://${module.geoserver.geoserver_service_host_port}"
}

// This module creates a compute instance to deploy MODERATE services that are in
// development and benefit from having an easier and quicker deployment process,
// rather than constantly updating Terraform resources.
module "dev_compute_instance" {
  source                 = "../modules/dev_compute_instance"
  zone                   = var.zone_default
  region                 = var.region
  network                = module.gke_cluster.cluster_network_name
  subnetwork             = module.gke_cluster.cluster_subnetwork_name
  devuser                = var.devuser_username
  devuser_ssh_public_key = var.devuser_ssh_public_key
}
